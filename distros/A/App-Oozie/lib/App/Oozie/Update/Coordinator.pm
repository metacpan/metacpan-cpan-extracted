package App::Oozie::Update::Coordinator;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.015'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    EMPTY_STRING
    ONE_HOUR
    RE_EQUAL
);
use App::Oozie::Types::Common qw( IsCOORDID );
use App::Oozie::Util::Misc qw( resolve_tmp_dir );

use Config::General qw( ParseConfig );
use Cwd;
use Date::Format ();
use Date::Parse  ();
use File::Spec::Functions qw( catfile );
use File::Temp ();
use Getopt::Long;
use IPC::Cmd ();
use Ref::Util       qw( is_ref );
use Types::Standard qw( HashRef );
use XML::Twig;

use Moo;
use MooX::Options prefer_commandline => 0,
                  protect_argv       => 0,
                  usage_string       => <<'USAGE',
Usage: %c %o [options] --coord <coord id>
USAGE
;

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Common
    App::Oozie::Role::Info
);

option coord => (
    is       => 'rw',
    isa      => IsCOORDID,
    format   => 's',
    required => 1,
    doc      => q{The ID of the coordinator you want to update},
);

option define => (
    is      => 'rw',
    format  => 's@',
    default => sub { [] },
    doc     => q{define or update a coordinator property, like "--define 'foo=bar'"},
);

option doas => (
    is     => 'rw',
    format => 's',
    lazy   => 1,
    doc    => 'User to impersonate as',
);

has override => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        +{}
    },
);

sub run {
    my $self   = shift;
    my $logger = $self->logger;

    $logger->info(
        sprintf 'Starting%s',
                $self->verbose  ? EMPTY_STRING
                                : '. Enable --verbose to see more information',
    );

    $self->log_versions if $self->verbose;

    my($job_meta, $job_properties) = $self->collect_current_conf;

    my $max_retry = $self->max_retry;
    my $state     = {};
    my ($twig, $success, $last_out);

    # 3 runs because we can either fail on start time, end time, or both (but if
    # both the 2 errors won't be displayed at the same time, so we need the
    # fix_starttime and fix_endtime flags. niiiice.

    TRY:
    for my $try ( 1..$max_retry ) {
        ($twig, $state) = $self->_modify_xml(
                                $job_meta->{current_xml_ref},
                                $job_properties,
                                $state,
                                $job_meta->{startTime},
                                $job_meta->{endTime},
                            );

        my $command = [
            $self->oozie_cli,
            '-Doozie.auth.token.cache=false',
            '-Duser.name=' . $job_meta->{current_coord_user},
            job => -update => $self->coord,
                   -config => $self->_dump_twig_to_temp_file( $twig ),
            -oozie => $self->oozie_uri,
            ($self->doas ? (-doas => $self->doas) : ()), #impersonation
        ];

        push @{ $command }, '-dryrun' if $self->dryrun;

        $logger->info(
            sprintf 'Updating the coordinator (%s) attempt: %s',
                        $self->coord,
                        $try,
        );

        $success = IPC::Cmd::run(
                        buffer  => \my $out,
                        command => $command,
                        timeout => $self->timeout,
                        verbose => $self->verbose || $job_meta->{show_cmd_output},
                    );

        $last_out = $out;

        if ( ! $success ) {
            if ( $out ) {
                if ( $out =~ m{ \QStart time can't be changed\E }xms ) {
                    $state->{fix_starttime} = 1;
                }

                if ( $out =~ m{ \QEnd time can't be changed\E }xms ) {
                    $state->{fix_endtime} = 1;
                }
            }
            else {
                $logger->warn(
                    sprintf 'Coordinator %s update failed (%s): %s',
                                $self->coord,
                                $self->dryrun ? ' (dryrun)' : EMPTY_STRING,
                                $out // '[no output]',
                );
            }
            next TRY;
        }

        $logger->info(
            sprintf 'Coordinator %s updated%s',
                        $self->coord,
                        $self->dryrun ? ' (dryrun)' : EMPTY_STRING,
        );

        last TRY;
    }

    if ( ! $success ) {
        $logger->fatal(
            sprintf 'Coordinator %s was NOT updated%s.',
                        $self->coord,
                        $self->dryrun ? ' (dryrun)' : EMPTY_STRING,
        );
        if ( $last_out ) {
            $logger->fatal( $last_out );
            if ( $last_out =~ m{ \QFrequency can't be changed\E }xms ) {
                $logger->fatal('Your running coordinator and the local coordinator.xml seems to have out of sync frequency settings. Please update coordinator.xml before continuing to reflect the scheduled job settings.');
            }
        }
    }

    return $success;
}

sub collect_current_conf {
    my $self   = shift;
    my $logger = $self->logger;
    my $coord  = $self->coord;

    my(
        $current_coord_user,
        $current_xml,
        $oozie_build,
        $oozie_cdh_version,
        $oozie_version,
        $base_path,
        $meta_startTime,
        $meta_endTime,
        %job_properties
    );

    eval {
        my $oozie           = $self->oozie;
        my $job             = $oozie->job( $coord )       || die sprintf 'No configuration for the job: %s', $coord;
        $oozie_build        = $oozie->new->build_version  || die 'Failed to get the Oozie server version!';
        my @vtuple          = split m{ \Q-cdh\E }xms, $oozie_build;
        $oozie_version      = shift @vtuple               || die sprintf 'Unable to determine the Oozie server version from %s', $oozie_build;
        $oozie_cdh_version  = shift @vtuple               || die sprintf 'Unable to determine the Oozie server CDH version from %s', $oozie_build;
        $current_coord_user = $job->{user}                || die sprintf 'Failed to locate the user running %s', $coord;
        $current_xml        = $job->{conf}                || die sprintf 'No configuration for the job: %s', $coord;
        # If you extend the coordinator, then this data gets updated but the
        # XML config will retain the old and meaningless record. While
        # it should be fine for the startTime, it will be bogus for the endTime
        # and our shifting logic/workaround will not do anything and in fact
        # the server will respond with an "Error: E0803" even when you want
        # to update everything but the scheduling. For some reason XML conf
        # does not get updated.
        #
        $meta_startTime     = $job->{startTime}           || die sprintf 'No startTime set for the job: %s', $coord;
        $meta_endTime       = $job->{endTime}             || die sprintf 'No endTime set for the job: %s', $coord;
        my $path            = $job->{coordJobPath}        || die sprintf 'No coordJobPath defined for the job: %s', $coord; # shouldn't happen
        my $hdfs_dest       = $self->default_hdfs_destination;
        ($base_path         = $path) =~ s{ \A $hdfs_dest [/]? }{}xms;
        my $jp_hdfs_path    = catfile $path,      'job.properties';
        my $jp_local_path   = catfile $base_path, 'job.properties';

        my $jp;
        my $hdfs = $self->hdfs;
        if ( my $meta = $hdfs->exists( $jp_hdfs_path ) ) {
            $logger->info( sprintf 'job.properties exists on HDFS. Fetching %s', $jp_hdfs_path );
            $jp = $hdfs->read( $jp_hdfs_path );
        }
        elsif ( -e $jp_local_path ) {
            $logger->info( sprintf 'job.properties exists on local file system. Fetching %s', $jp_local_path );
            open my $FH, '<', $jp_local_path or die sprintf q{Can't read %s: %s}, $jp_local_path, $!;
            $jp =  do { local $/; <$FH> };
            if ( ! close $FH ) {
                $logger->warn(
                    sprintf 'Failed to close %s: %s',,
                                $jp_local_path,
                                $!,
                );
            }
        }
        else {
            my $uh_oh = sprintf <<'FYI', Cwd::getcwd, $base_path;

No job.properties file neither on hdfs nor local file system.
There are no parameter overrides to collect.

This program looks at relative paths to search for local files.

Your current working directory is %s and search path is %s.

If this is not the directory for the local application files, please change
to the proper location and try again.

FYI
            $logger->warn( $uh_oh );
        }

        %job_properties = $jp ? ParseConfig( -String => $jp ) : ();

        for my $name ( keys %job_properties ) {
            my $val = $job_properties{ $name};
            if ( is_ref $val ) {
                require Data::Dumper;
                my $d = Data::Dumper->new([ $val ], [ $name ]);
                $logger->logdie(
                    sprintf 'You seem to have a double definition in %s for %s as %s',
                                'job.properties',
                                $name,
                                $d->Dump,
                );
            }
        }

        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        $logger->fatal(
            sprintf 'Could not get config for job %s: %s',
                        $coord,
                        $eval_error,
        );
        die 'Failed.';
    };

    if ( $self->verbose ) {
        $logger->debug( 'Start Current XML configuration' );
        $logger->debug( $current_xml );
        $logger->debug( 'End Current XML configuration' );
    }

    my $show_cmd_output;
    if (   $oozie_cdh_version        ge '5.8.0'
        && $self->effective_username ne $current_coord_user
    ) {
        $logger->warn(
            sprintf 'Current user `%s` is not the same as the coordinator user: `%s`. Will attempt to impersonate.',
                        $self->effective_username,
                        $current_coord_user,
        );
    }

    my %job_meta = (
        current_coord_user => $current_coord_user,
        current_xml_ref    => \$current_xml,
        startTime          => $meta_startTime,
        endTime            => $meta_endTime,
        show_cmd_output    => $show_cmd_output || 0,
    );

    return \%job_meta, \%job_properties;
}

sub offset_one_hour {
    my $self = shift;
    my $time = shift;

    # Set a - 1H offset on the second try, to work around the oozie
    # coord update bug linked to oozie 3 and DST
    return Date::Format::time2str(
                '%Y-%m-%dT%H:%MZ',
                Date::Parse::str2time( $time->text ) - ONE_HOUR,
                'UTC',
            );
}

sub _modify_xml {
    my $self            = shift;
    my $current_xml_ref = shift;
    my $job_properties  = shift;
    my $prev_state      = shift || {}; # might be set by retries
    my $meta_startTime  = shift;
    my $meta_endTime    = shift;

    my $logger = $self->logger;

    $logger->debug( sprintf 'Coordinator XML is being verified ...' )
        if $self->verbose;

    my $twig = XML::Twig->new->parse( ${ $current_xml_ref } )
                or die 'Could not parse the original configuration';

    # clean up former mistakes...
    for my $elem ( $twig->root->children ) {
        if ( $elem->first_child_text =~ m{ \A ["]oozie[.] }xms ) {
            $elem->delete;
        }
    }

    SYNC_END_TIME_IN_XML_CONF: {
        for my $elem ( $twig->root->children ) {
            for my $date_field (qw/
                endTime
                startTime
            /) {
                if ( $elem->first_child_text eq $date_field ) {
                    my($cur) = $elem->get_xpath('./value');
                    my $meta_val = $date_field eq 'endTime'   ? $meta_endTime
                                 : $date_field eq 'startTime' ? $meta_startTime
                                 : die "Unknown field $date_field"
                                 ;
                    # Such conditions can be triggered by:
                    #      i) Extending endTime afterwards and Oozie coord config vs
                    #         live config diverging.
                    #     ii) Coord scheduled around the DST change getting effected
                    #         due to the scheduling using non-UTC TZ, which will
                    #         end up with startTime being off by one when doing this check.
                    #
                    my $fmt_val = Date::Format::time2str(
                        '%Y-%m-%dT%H:%MZ',
                        Date::Parse::str2time( $meta_val ),
                        'UTC'
                    );
                    if ( $cur->text ne $fmt_val ) {
                        $logger->info(
                            sprintf 'Coordinator XML config is out of sync. Attempting to update %s from obsolete %s to the current %s. This is only a consistency update and a no-op change for the running coordinator.',
                                        $date_field,
                                        $cur->text,
                                        $fmt_val,
                        );
                        $cur->set_text( $fmt_val );
                    }
                    else {
                        $logger->debug( sprintf 'Coordinator %s seems to be in sync', $date_field );
                    }
                }
            }
        }
    }

    if ( $prev_state->{fix_endtime} ) {
        for my $elem ( $twig->root->children ) {
            if ( $elem->first_child_text eq 'endTime' ) {
                # change the value inside the <value> tag
                my ($endTime) = $elem->get_xpath('./value');
                $endTime->set_text( $self->offset_one_hour( $endTime ) );
            }
        }
    }

    if ( $prev_state->{fix_starttime} ) {
        for my $elem ( $twig->root->children ) {
            if ( $elem->first_child_text eq 'startTime' ) {
                # change the value inside the <value> tag
                my ($startTime) = $elem->get_xpath('./value');
                $startTime->set_text( $self->offset_one_hour( $startTime ) );
            }
        }
    }
    my %twig_keyval_pair;
    if ( keys %{ $job_properties } ) {
        # Collect and update only the changed parameters
        for my $kid ( $twig->root->children ) {
            my $k = $kid->first_child_text;
            my $v = $kid->last_child_text;
            $twig_keyval_pair{$k} = $v;
            if (   ! exists $job_properties->{ $k }
                || $k eq 'endTime'
                || $k eq 'startTime'
            ) {
                next;
            }
            my $new_v = $job_properties->{ $k };
            next if $new_v eq $v;
            my($e) = $kid->get_xpath('./value');
            $e->set_text( $new_v );
        }

        #Add new properties
        foreach my $key (keys %{$job_properties})
        {
            if ( $key eq 'endTime' || $key eq 'startTime') {next;}
            if (exists $twig_keyval_pair{$key}) {next;}
            $twig->root->insert_new_elt(
                'last_child',
                'property',
                {},
                XML::Twig::Elt->new( 'name',  {}, $key ),
                XML::Twig::Elt->new( 'value', {}, $job_properties->{$key} ),
            );
        }
    }

    for ( @{ $self->define } ) {
        my ( $k, $v ) = split RE_EQUAL, $_, 2;
        $twig->root->insert_new_elt(
            'last_child',
            'property',
            {},
            XML::Twig::Elt->new( 'name',  {}, $k ),
            XML::Twig::Elt->new( 'value', {}, $v ),
        );
    }

    my $override = $self->override;

    for my $k ( keys %{ $override } ) {
        my $v = $override->{ $k };
        $twig->root->insert_new_elt(
            'last_child',
            'property',
            {},
            XML::Twig::Elt->new( 'name',  {}, $k ),
            XML::Twig::Elt->new( 'value', {}, $v ),
        );
    }

    $logger->debug( sprintf 'Coordinator XML verification completed.' )
        if $self->verbose;

    return $twig, $prev_state;
}

sub _dump_twig_to_temp_file {
    my $self = shift;
    my $twig = shift;
    my $tmp  = File::Temp->new(
                    DIR    => resolve_tmp_dir(),
                    SUFFIX => '.xml',
                );

    $twig->set_xml_version('1.0');
    $twig->set_pretty_print('indented');
    $twig->print( $tmp );

    print $tmp "\n";

    $self->_show_twig( $twig ) if $self->verbose;

    return $tmp;
}

sub _show_twig {
    my $self   = shift;
    my $twig   = shift;
    my $logger = $self->logger;

    $logger->debug( 'Start new XML configuration' );

    open my $BUF, '>', \my $dump
        or die sprintf 'Failed to create an in-memory filehandle: %s', $!;

    $twig->flush( $BUF );

    if ( ! close $BUF ) {
        $logger->warn(
            sprintf 'Failed to close in-memory XML file: %s',
                        $!,
        );
    }

    $logger->debug( $dump );
    $logger->debug( 'End new XML configuration' );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Update::Coordinator

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use App::Oozie::Update::Coordinator;
    App::Oozie::Update::Coordinator->new_with_options->run;

=head1 DESCRIPTION

This is an action/program in the Oozie Tooling.

=head1 NAME

App::Oozie::Update::Coordinator - Updates the running coordinator.

=head1 Methods

=head2 run

=head2 collect_current_conf

=head2 offset_one_hour

=head1 Accessors

=head2 Overridable from cli

=head3 coord

=head3 define

=head3 doas

=head2 Overridable from sub-classes

=head3 override

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
