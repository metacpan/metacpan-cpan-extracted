package App::Gitc::Its::Jira;
use strict;
use warnings;

# ABSTRACT: Support for Atlassian JIRA ITS (Issue Tracking System)
our $VERSION = '0.60'; # VERSION


use JIRA::Client;
use JIRA::Client::REST;
use Try::Tiny;
use List::MoreUtils qw( any );
use YAML;

use App::Gitc::Util qw(
    project_config
    command_name
    current_branch
);


sub label_service { return 'JIRA'; }
sub label_issue   { return 'Issue'; }

our $default_jira_user     = 'someuser';
our $default_jira_password = 'somepassword';
our $jira_conf;

sub lookup_jira_user {
    my $self = shift;
    if (not $jira_conf and -e "$ENV{HOME}/.gitc/jira.conf") {
        $jira_conf = YAML::LoadFile("$ENV{HOME}/.gitc/jira.conf");
    } else {
        $jira_conf = {};
    }
    my $jira_user     = $jira_conf->{user} || $default_jira_user;
    my $jira_password = $jira_conf->{password} || $default_jira_password;
    return ($jira_user, $jira_password);
}

sub lookup_status_strings
{
    my $self = shift;

    my $jira = $self->get_jira_object or return;

    my $statuses = $jira->getStatuses();
    return unless $statuses;

    return { map { $_->{id} => $_->{name} } @{$statuses} };
}

sub get_jira_object
{
    my $self = shift;

    # to find an JIRA issue, we need a number and URI
    my $uri = project_config()->{'jira_uri'} or return;

    # build and return the Issue object
    our %jira;
    my $jira = $jira{$uri};
    if ( not $jira ) {
        my ($jira_user, $jira_password) = $self->lookup_jira_user;
        $jira{$uri} = $jira
            = JIRA::Client->new( $uri, $jira_user, $jira_password );
        die "Unable to connect to JIRA SOAP API" unless $jira;
    }

    return $jira;
}

sub get_jira_rest_object {
    my $self = shift;

    # to find an JIRA issue, we need a number and URI
    my $uri    = project_config()->{'jira_uri'} or return;

    # build and return the Issue object
    our %jira_rest;
    my $jira = $jira_rest{$uri};
    if ( not $jira ) {
        my ($jira_user, $jira_password) = $self->lookup_jira_user;
        $jira_rest{$uri} = $jira = JIRA::Client::REST->new(
               username => $jira_user,
               password => $jira_password,
               url => $uri,
           );
        die "Unable to connect to JIRA REST API" unless $jira;
    }

    return $jira;
}

sub get_issue {
    my $self = shift;
    my $changeset = shift;
    my %params = @_;
    my $number = $self->issue_number($changeset) or return undef;
    our %jira_issue;
    return $jira_issue{$number}
        if exists $jira_issue{$number} and not $params{reload};

    my $issue = eval {
        my $jira = $self->get_jira_object or return;
        my $issue = $jira->getIssue($number);
        die "Issue $number didn't return an object" unless $issue;
        return $jira_issue{$number} = $issue;
    };

    warn "Error accessing JIRA: $@" if $@;
    return $issue; 
}

sub transition_state {
    my $self = shift;
    my ($args) = @_;
    $args ||= {};
    $args->{with_time} = 1 unless exists $args->{with_time};
    return "Skipping JIRA changes, as requested by GITC_NO_EVENTUM\n"
        if $ENV{GITC_NO_EVENTUM};
    return "Skipping JIRA changes as configured for this project\n"
        if not project_config()->{'jira_uri'};

    my $label = $self->label_issue;

    # validate the arguments
    my $command = $args->{command} || command_name();
    my $state = $self->_states( $command, $args->{target} );
    my $from = $state->{from};
    my $to = $state->{to};
    my $flag = $state->{flag};
    my $message = $args->{message} or die "No message";
    my $reviewer = $args->{reviewer};
    my $issue = exists $args->{issue} ? $args->{issue} :
                                        $self->get_issue(current_branch(), reload => 1);
    return "NOT CHANGING JIRA $label: changeset not in JIRA?\n"
        if not $issue;

    my ($jira_user) = $self->lookup_jira_user;
    $message = (getpwuid $>)[6]   # user's name
                . ": $message\n";

    $message = $flag." ".$message if $flag;

    my ( $rc, $status_exception );
    eval {
        my $jira = $self->get_jira_object or return;
        $jira->addComment( $issue, $message );
        my $updated_issue = $jira->progress_workflow_action_safely( $issue, $to );
        my $jira_rest = $self->get_jira_rest_object or return;
        $jira_rest->unwatch_issue( $issue->{id}, $jira_user )
            if $jira_user eq $default_jira_user;
        $rc = ( $issue->{id} == $updated_issue->{id} );
    };
    die $@ if $@;  # rethrow unexpected exceptions

    if ($reviewer) {
        eval {
            my $jira = $self->get_jira_object or return;
            $jira->update_issue( $issue,
                { custom_fields => { customfield_10401 => $reviewer, } } );
        };
        warn "Unable to set reviewer: $@" if $@;
    }

    if ( $status_exception ) {
        die $status_exception
            if $status_exception !~ m/('[^']+' is not a valid status name)/;
        return "NOT CHANGING JIRA $label: $1\n";
    }
    elsif ($rc) {  # success
        return "Changed JIRA $label to '$to'\n";
    }
    else {
        return sprintf "NOT CHANGING JIRA $label: currently '%s'\n",
            $self->issue_state($issue);
    }
}


sub issue_state {
    my $self = shift;
    my $issue = shift;
    
    return unless $issue;
    my $status_lookup = $self->lookup_status_strings;

    return $status_lookup->{$issue->{status}} if $status_lookup && exists $status_lookup->{$issue->{status}};
    return $issue->{status};
}

sub issue_number {
    my $self = shift;
    my ($changeset_or_issue) = @_;

    return $changeset_or_issue->{key} if ref $changeset_or_issue;

    $changeset_or_issue =~ s/[a-z]+$//;
    
    return $changeset_or_issue;
}

sub issue_id {
    my $self = shift;
    my $issue = shift;

    return $issue->{key};
}

sub issue_changeset_uri {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    # to find an JIRA issue, we need a number and URI
    my $its_uri = project_config()->{'jira_uri'};
    return unless $its_uri;

    my $uri = eval { sprintf( '%s/browse/%s', $its_uri, $issue->key ); } || '';
    return $uri;
}

sub issue_summary {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return $issue->{summary};
}

sub issue_promotion_notes {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return unless $issue->{customFieldValues};
    my ($val_obj)
        = grep { $_->{'customfieldId'} eq 'customfield_10302' } # ID for 'Promotion Related Notes' in TE Project
        @{ $issue->{customFieldValues} };
    return unless $val_obj;
    return join( "\n", @{ $val_obj->{values} } );
}

sub issue_project {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return $issue->{project};
}

sub issue_scheduled_release {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return unless $issue->{fixVersions} && @{$issue->{fixVersions}};

    return $issue->{fixVersions}->[-1]->{name}; #.' ('.$issue->{fixVersions}->[-1]->{releaseDate}.')';
}

1;

__END__

=pod

=head1 NAME

App::Gitc::Its::Jira - Support for Atlassian JIRA ITS (Issue Tracking System)

=head1 VERSION

version 0.60

=head1 DESCRIPTION

Uses a mix of both SOAP and REST APIs.

Eventually this should be migrated to fully use the REST API once it is mature.

=head1 METHODS

=head2 label_service label_issue

Return strings used to label the service and issue for (error) reporting purposes

=head2 get_jira_object

Returns a JIRA object used to access the SOAP API

=head2 get_jira_rest_object

Returns a JIRA object used to access the REST API

=head2 get_issue 

Returns an object representing this changeset's JIRA issue.  

If this changeset has no JIRA issue or there was an error locating
it, returns C<undef>.  Normally this will cache the object, and return it
on subsequent calls.  If the C<reload> parameter is set, it will reload the
object and reset the cache.

=head2 transition_state

Change an issue's status from one value to another by progressing using
a JIRA action to progress the workflow.

The following named arguments are understood:

 message   - required message to put in JIRA's Internal Comments
 issue     - optional JIRA issue object
             (defaults to an Issue for the currently checked out changeset)
 command   - optional name of the command that's changing the status
             (by default, it's inferred from the top-level script)
 target    - optional name of a promotion target (when $command is 'promote')
 flag      - a emoticon used for JIRA comments to flag the action

The old and new statuses are specified through the project configuration.  
They are keyed on the value of the C<command> argument.

=head2 issue_*

These return the correct field based on being passed in an jira issue object.
Think of it as $issue->*  - Should be replaced with a facade for issues

=head2 issue_state

Returns the current issue 'state' (usually status), this may or may not match the config from/target states

=head2 issue_number

Returns the JIRA issue number for a given changeset name OR given an JIRA issue object

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Grant Street Group.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
