package App::Oozie::Rerun;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants       qw(
    DEFAULT_OOZIE_MAX_JOBS
    EMPTY_STRING
    HOURS_IN_A_DAY
    ONE_HOUR
    RE_AT
);
use App::Oozie::Types::DateTime qw( IsDateStr );
use App::Oozie::Types::States   qw( IsOozieStateRerunnable );
use Date::Parse ();
use IPC::Cmd    ();
use Template;
use Types::Standard qw( ArrayRef Int Str );
use Moo;
use MooX::Options prefer_commandline => 0,
                  protect_argv       => 0,
                  usage_string       => <<'USAGE',
Usage: %c %o [options]

Reprocess or resume killed or suspended coordinator actions

This utility will check which actions match the given conditions, and display a
list of command lines to copy and paste in a terminal, either to rerun or
resume, depending on the task status

USAGE
;

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Common
    App::Oozie::Role::Info
);

option name => (
    is     => 'rw',
    isa    => Str,
    format => 's',
    doc    => 'Only return actions which matches this regex. Default: everything.',
);

option hours => (
    is      => 'rw',
    isa     => Int,
    format  => 'i',
    doc     => 'Lower boundary for failure (number of hours back)',
);

option maxjobs => (
    is      => 'rw',
    isa     => Int,
    default => sub { DEFAULT_OOZIE_MAX_JOBS },
    format  => 'i',
    short   => 'max',
    doc     => 'Maximum number of failed tasks to check in one run (defaults to 1000)',
);

option resurrect_coord => (
    is     => 'rw',
    doc    => 'Dead coordinators and actions for them will be skipped. Specify this to do otherwise.',
);

option since => (
    is     => 'rw',
    isa    => IsDateStr,
    format => 's',
    doc    => 'Lower boundary for failure (date/time passed to str2time)',
);

option status => (
    is      => 'rw',
    isa     => IsOozieStateRerunnable,
    default => sub { [qw/ KILLED /] },
    format  => 's@',
    doc     => 'List of job status(es) to filter jobs.',
);

option execute => (
    is  => 'rw',
    doc => 'Execute the commands instead of displaying on screen?',
);

has when => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->since ? Date::Parse::str2time $self->since
                     : time - ( $self->hours || HOURS_IN_A_DAY) * ONE_HOUR
                     ;
    },
);

sub BUILD {
    my ($self, $args) = @_;
    if ( exists $args->{hours} && exists $args->{since} ) {
        die '--hours and --since are mutually exclusive';
    }
}

sub run {
    my $self = shift;

    $self->log_versions if $self->verbose;

    my $reruns = $self->collect || do {
        $self->logger->info( 'No failed jobs matching your conditions' );
        return;
    };

    return $self->execute
                ? $self->execute_reruns( $reruns )
                : $self->dump_for_shell( $reruns )
                ;
}

sub execute_reruns {
    my $self    = shift;
    my $reruns  = shift;

    my $logger  = $self->logger;

    my @cmd_common = (
        $self->oozie_cli,
        'job',
        -oozie => $self->oozie->oozie_uri,
    );

    for my $idx (sort keys %{ $reruns } ) {
        my $slot = $reruns->{ $idx };
        my @cmd = (
            @cmd_common,
            split( m{ \s+ }xms, $slot->{cmd} ),
            $slot->{coord_job_id},
            '-action',
            $slot->{action_number},
        );
        $logger->info(
            sprintf 'Rerunning %s action #%s: nominal time: %s last modified: %s',
                        @{ $slot }{qw/
                            name
                            action_number
                            nominal_time
                            last_mtime
                        /}
        );
        $logger->info("@cmd");

        my ( $ok, $err, $full_buf, $stdout_buff, $stderr_buff ) = IPC::Cmd::run(
            command => \@cmd,
            verbose => $self->verbose,
            timeout => $self->timeout,
        );

        if ( ! $ok ) {
            my $msg = join "\n", @{
                       $stderr_buff
                    || $stdout_buff
                    || ["Timed out (can happen is the local host is overloaded)? Unknown error from @cmd"]
                    };
            $logger->logdie( $msg );
        }
        my $msg = $stdout_buff
                ? do {
                        my @rv = @{ $stdout_buff };
                        join "\n",
                            grep { $_ }
                            map { chomp; $_ }
                            @rv >= 3 ? @rv[3..$#rv] : @rv; ## no critic (ProhibitMagicNumbers)
                    }
                : EMPTY_STRING
                ;

        $logger->info( 'Oozie said: ' . $msg );
    }

    return;
}

sub dump_for_shell {
    my $self   = shift;
    my $reruns = shift;

    my $program   = $self->oozie_cli;
    my $oozie_uri = $self->oozie->oozie_uri;
    my $t         = Template->new;

    my $tmpl = <<'COMMAND';
: [% app_name %] - [% workflow_id %]
: nominal time: [% nominal_time %] last modified: [% last_mtime %]
[% oozie_cli %] job -oozie [% oozie_uri %] [% commands %] [% coord_job_id %] -action [% coord_action_number %]

COMMAND

    print "\n";

    for (sort keys %{ $reruns } ) {
        my $slot = $reruns->{$_};
        $t->process(
            \$tmpl,
            {
                commands            => $slot->{cmd},
                coord_action_number => $slot->{action_number},
                coord_job_id        => $slot->{coord_job_id},
                app_name            => $slot->{name},
                last_mtime          => $slot->{last_mtime},
                nominal_time        => $slot->{nominal_time},
                oozie_cli           => $program,
                oozie_uri           => $oozie_uri,
                workflow_id         => $slot->{id},
            },
            \my $output,
        );

        chomp $output;

        printf "%s\n", $output;

    }

    print <<'MSG';
: *****************************************************************************************
: Copy the above lines and paste them in a terminal - after checking the output is sensible.
: the lines starting with a colon like this one will be no-ops, so you can paste them too.

MSG

    return;
}

sub collect {
    my $self = shift;

    my $logger    = $self->logger;
    my $oozie     = $self->oozie;
    my $re_name   = $self->name;
    my $resurrect = $self->resurrect_coord;
    my $verbose   = $self->verbose;
    my $when      = $self->when;

    my $jobs  = $oozie->jobs(
                    filter => {
                        status => $self->status,
                    },
                    len => $self->maxjobs,
                );

    return if ! $jobs || ! $jobs->{workflows};

    my @candidates = grep {
                    $when <= (
                        $_->{lastModTime_epoch}
                     || $_->{lastModifiedTime_epoch}
                    )
                } @{ $jobs->{workflows} };

    return if ! @candidates;

    my(%seen, %coord_cache);

    my %is_status = map { $_ => 1 } @{ $self->status };
    my $reruns    = {};
    $re_name      = qr{ $re_name }xms if $re_name;

    for my $fail ( @candidates ) {

        my $name = $fail->{appName};
        my $id   = $fail->{id};
        my $cid  = $fail->{parentId}
                    ? ( split RE_AT, $fail->{parentId} )[0]
                    : undef
                    ;

        if (   ! $fail->{parentId} # Standalone WF, it can't be re-run.
            || $seen{ $cid }
            || ( $re_name && $fail->{appName} !~ $re_name )
        ) {
            if ( $verbose ) {
                $logger->debug(
                    sprintf 'Skipping %s [%s] -> does not match the criterias',
                                $id || 'N/A',
                                $name,
                );
            }
            next;
        }

        my $coord = $coord_cache{ $cid } ||= $oozie->job( $cid );
        my $job   = $oozie->job( $fail->{parentId} );

        if ( $coord->{status} eq 'KILLED' && ! $resurrect ) {
            if ( ! $seen{ $cid }++ ) {
                $logger->warn( "Coordinator $name ( $cid ) is dead. Skipping (see --help)" );
            }
            next;
        }

        if ( ! $job->{coordJobId} || ! $is_status{ uc $job->{status} } ) {
            if ( $verbose ) {
                $logger->debug(
                    sprintf 'Skipping %s %s [%s] -> either not a corodinator action or not matching the status list',
                                $id || 'N/A',
                                $job->{status},
                                $name,
                );
            }
            next;
        }

        my $key = $job->{coordJobId} . q{#} . $job->{actionNumber};

        # keep them in a hash, we will sort the keys so the actions are in
        # asccending order for a coordinator when issuing the bash commands; only
        # keep the most recent failure for a given coord+action

        my $last_mtime =  $job->{lastModTime_epoch} || $job->{lastModifiedTime_epoch};

        if (   ! $reruns->{$key}
            || $last_mtime > $reruns->{ $key }{last_mtime_epoch}
        ) {
            my $cmd = $job->{status} =~ m{ susp }xmsi
                    ? '-resume'
                    : '-refresh -rerun'
                    ;

            $reruns->{ $key } = {
                action_number    => $job->{actionNumber}     || EMPTY_STRING,
                cmd              => $cmd,
                coord_job_id     => $job->{coordJobId}       || EMPTY_STRING,
                id               => $id                      || EMPTY_STRING,
                last_mtime       => $job->{lastModifiedTime} || EMPTY_STRING,
                last_mtime_epoch => $last_mtime,
                name             => $name                    || EMPTY_STRING,
                nominal_time     => $job->{nominalTime}      || EMPTY_STRING,
            };
        }
    }

    return if ! %{ $reruns };

    return $reruns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Rerun

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use App::Oozie::Rerun;
    App::Oozie::Rerun->new_with_options->run;

=head1 DESCRIPTION

This is an action/program in the Oozie Tooling.

=for Pod::Coverage BUILD

=head1 NAME

App::Oozie::Rerun - The program to re-run Oozie workflows.

=head1 Methods

=head2 collect

=head2 dump_for_shell

=head2 execute_reruns

=head2 run

=head1 Accessors

=head2 Overridable from cli

=head3 execute

=head3 hours

=head3 maxjobs

=head3 name

=head3 resurrect_coord

=head3 since

=head3 status

=head2 Overridable from sub-classes

=head3 when

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
