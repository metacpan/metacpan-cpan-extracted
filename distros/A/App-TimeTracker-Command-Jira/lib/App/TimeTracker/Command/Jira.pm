package App::TimeTracker::Command::Jira;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Jira plugin
use App::TimeTracker::Utils qw(error_message warning_message);

our $VERSION = '0.5';

use Moose::Role;
use JIRA::REST ();
use JSON::XS qw(encode_json decode_json);
use Path::Class;
use Try::Tiny;
use Unicode::Normalize ();

has 'jira' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'JIRA ticket ID',
    predicate     => 'has_jira'
);
has 'jira_client' => (
    is         => 'ro',
    isa        => 'Maybe[JIRA::REST]',
    lazy_build => 1,
    traits     => ['NoGetopt'],
    predicate  => 'has_jira_client'
);
has 'jira_ticket' => (
    is         => 'ro',
    isa        => 'Maybe[HashRef]',
    lazy_build => 1,
    traits     => ['NoGetopt'],
);
has 'jira_ticket_transitions' => (
    is         => 'rw',
    isa        => 'Maybe[ArrayRef]',
    traits     => ['NoGetopt'],
);

sub _build_jira_ticket {
    my ($self) = @_;

    if ( my $ticket = $self->_init_jira_ticket( $self->_current_task ) ) {
        return $ticket;
    }
}

sub _build_jira_client {
    my $self   = shift;
    my $config = $self->config->{jira};

    unless ($config) {
        error_message('Please configure Jira in your TimeTracker config');
        return;
    }

    unless ($config->{username} and $config->{password}) {
        error_message('No Jira account credentials configured');
        return;
    }

    return JIRA::REST->new($config->{server_url}, $config->{username}, $config->{password});

}

before [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;
    return unless $self->has_jira;

    $self->insert_tag('JIRA:' . $self->jira);

    my $ticket;
    if ( $self->jira_client ) {
        $ticket = $self->jira_ticket;
        return unless defined $ticket;
        if ( defined $self->description ) {
            $self->description(
                sprintf(
                    '%s (%s)', $self->description, $ticket->{fields}->{summary}
                ) );
        }
        else {
            $self->description( $ticket->{fields}->{summary} // '' );
        }
    }

    if ( $self->meta->does_role('App::TimeTracker::Command::Git') ) {
        my $branch = $self->jira;
        if ($ticket) {
            my $subject = $self->_safe_ticket_subject( $ticket->{fields}->{summary} // '' );
            $branch .= '_' . $subject;
        }
        $self->branch($branch) unless $self->branch;
    }
};

after [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;
    return unless $self->has_jira && $self->jira_client;

    my $ticket = $self->jira_ticket;
    return unless defined $ticket;

    if ( $self->config->{jira}->{set_status}{start}->{transition}
            and $self->config->{jira}->{set_status}{start}->{target_state} ) {
        my $ticket_update_data;

        my $status = $self->config->{jira}->{set_status}{start}->{target_state};
        if ( $status and $status ne $ticket->{fields}->{status}->{name} ) {
            if ( my $transition_id = $self->_check_resolve_ticket_transition(
                $self->config->{jira}->{set_status}{start}->{transition}
            ) ) {
                $ticket_update_data->{transition}->{id} = $transition_id;
            }
        }

        if ( defined $ticket_update_data ) {
            my $result;
            try {
                $result = $self->jira_client->POST(
                    sprintf('/issue/%s/transitions', $self->jira),
                    undef,
                    $ticket_update_data,
                );
            }
            catch {
                error_message( 'Could not set JIRA ticket ticket status: "%s"', $_ );
            };
        }
    }
};

after 'cmd_stop' => sub {
    my $self = shift;
    return unless $self->jira_client;

    my $task = $self->_previous_task;
    return unless $task;
    my $task_rounded_minutes = $task->rounded_minutes;
    return unless $task_rounded_minutes > 0;

    my $ticket = $self->_init_jira_ticket($task);
    if ( not defined $ticket ) {
        say
            'Last task did not contain a JIRA ticket id, not updating TimeWorked or Status.';
        return;
    }

    my $do_store = 0;
    if ( $self->config->{jira}->{log_time_spent} ) {
        my $result;
        try {
            $result = $self->jira_client->POST(sprintf('/issue/%s/worklog', $task->jira_id), undef, { timeSpent => sprintf('%sm', $task_rounded_minutes) });
        }
        catch {
            error_message( 'Could not log JIRA time spent: "%s"', $@ );
        };
    }

    my $status = $self->config->{jira}->{set_status}{stop}->{transition};
    # Do not change the configured stop status if it has been changed since starting the ticket
    if ( defined $status
        and $ticket->{fields}->{status}->{name} eq
        $self->config->{jira}->{set_status}{start}->{target_state} )
    {
        if ( my $transition_id = $self->_check_resolve_ticket_transition( $status ) ) {
            my $ticket_update_data;
            $ticket_update_data->{transition}->{id} = $transition_id;

            my $result;
            try {
                $result = $self->jira_client->POST(
                    sprintf('/issue/%s/transitions', $task->jira_id),
                    undef,
                    $ticket_update_data,
                );
            }
            catch {
                error_message( 'Could not set JIRA ticket status: "%s"', $@ );
            };
        }
    }
};

sub _init_jira_ticket {
    my ( $self, $task ) = @_;
    my $id;
    if ($task) {
        $id = $task->jira_id;
    }
    elsif ( $self->jira ) {
        $id = $self->jira;
    }
    return unless defined $id;

    my $ticket;
    try {
        $ticket = $self->jira_client->GET(sprintf('/issue/%s',$id), { fields => '-comment' });
    }
    catch {
        error_message( 'Could not fetch JIRA ticket: %s', $id );
    };

    my $transitions;
    try {
        $transitions = $self->jira_client->GET(sprintf('/issue/%s/transitions',$id));
    }
    catch {
        require Data::Dumper;
        error_message( 'Could not fetch JIRA transitions for %s: %s', $id, Data::Dumper::Dumper $transitions );
    };
    $self->jira_ticket_transitions( $transitions->{transitions} );

    return $ticket;
}

sub _check_resolve_ticket_transition {
    my ( $self, $status_name ) = @_;
    my $transition_id;

    foreach my $transition ( @{$self->jira_ticket_transitions} ) {
        if ( ref $status_name and ref $status_name eq 'ARRAY' ) {
            foreach my $name ( @$status_name ) {
                if ( $transition->{name} eq $name ) {
                    $transition_id = $transition->{id};
                    last;
                }
            }
        }
        elsif ( $transition->{name} eq $status_name ) {
            $transition_id = $transition->{id};
            last;
        }
    }
    if ( not defined $transition_id ) {
        require Data::Dumper;
        error_message( 'None of the configured ticket transitions (%s) did match the ones valid for this JIRA ticket\'s workflow-state: %s',
            ref $status_name ? join(',', map { '"'.$_.'"' } @$status_name) : $status_name,
            join(',', map { '"'.$_->{name}.'"' } @{$self->jira_ticket_transitions} ),
        );
        return;
    }
    return $transition_id;
}

sub App::TimeTracker::Data::Task::jira_id {
    my $self = shift;
    foreach my $tag ( @{ $self->tags } ) {
        next unless $tag =~ /^JIRA:(.+)/;
        return $1;
    }
    return;
}

sub _safe_ticket_subject {
    my ( $self, $subject ) = @_;

    $subject = Unicode::Normalize::NFKD($subject);
    $subject =~ s/\p{NonspacingMark}//g;
    $subject =~ s/\W/_/g;
    $subject =~ s/_+/_/g;
    $subject =~ s/^_//;
    $subject =~ s/_$//;
    return $subject;
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::Jira - App::TimeTracker Jira plugin

=head1 VERSION

version 0.5

=head1 DESCRIPTION

This plugin integrates into Atlassian Jira
L<https://www.atlassian.com/software/jira>.

It can set the description and tags of the current task based on data
coming from Jira, set the owner of the ticket and update the
worklog. If you also use the C<Git> plugin, this plugin will
generate branch names based on Jira ticket information.

=head1 CONFIGURATION

=head2 plugins

Add C<Jira> to the list of plugins.

=head2 jira

add a hash named C<jira>, containing the following keys:

=head3 server [REQUIRED]

The URL of the Jira instance (without a trailing slash).

=head3 username [REQUIRED]

Username to connect with.

=head3 password [REQUIRED]

Password to connect with. Beware: stored in clear text!

=head3 log_time_spent

If set, an entry will be created in the ticket's work log

=head1 NEW COMMANDS ADDED TO THE DEFAULT ONES

none

=head1 CHANGES TO DEFAULT COMMANDS

=head2 start, continue

=head3 --jira

    ~/perl/Your-Project$ tracker start --jira ABC-1

If C<--jira> is set to a valid ticket identifier:

=over

=item * set or append the ticket subject in the task description ("Adding more cruft")

=item * add the ticket number to the tasks tags ("ABC-1")

=item * if C<Git> is also used, determine a save branch name from the ticket identifier and subject, and change into this branch ("ABC-1_adding_more_cruft")

=item * updates the status of the ticket in Jira (given C<set_status/start/transition> is set in config)

=back

=head2 stop

If <log_time_spent> is set in config, adds and entry to the worklog of the Jira ticket.
If <set_status/stop/transition> is set in config and the current Jira ticket state is <set_status/start/target_state>, updates the status of the ticket

=head1 EXAMPLE CONFIG

    {
        "plugins" : [
            "Git",
            "Jira"
        ],
        "jira" : {
            "username" : "dingo",
            "password" : "secret",
            "log_time_spent" : "1",
            "server_url" : "http://localhost:8080",
            "set_status": {
                "start": { "transition": ["Start Progress", "Restart progress", "Reopen and start progress"], "target_state": "In Progress" },
                "stop": { "transition": "Stop Progress" }
            }
        }
    }

=head1 AUTHOR

Michael Kröll <pepl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael Kröll.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
