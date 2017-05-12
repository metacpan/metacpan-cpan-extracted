package App::Gitc::Its::Eventum;
use strict;
use warnings;

# ABSTRACT: Support for Eventum ITS (Issue Tracking System)
our $VERSION = '0.60'; # VERSION


use POSIX qw( strftime );

use App::Gitc::Util qw(
    project_config
    command_name
    current_branch
);

use List::MoreUtils qw( any );

sub label_service { return 'Eventum'; }
sub label_issue { return 'Eventum'; }



sub get_issue {
    my $self = shift;
    my $changeset = shift;
    my %params = @_;
    my $number = $self->issue_number($changeset) or return undef;
    our %eventum_issue;
    return $eventum_issue{$number}
        if exists $eventum_issue{$number} and not $params{reload};

    # to find an Eventum issue, we need a number and URI
    my $uri    = project_config()->{'eventum_uri'} or return;

    # build and return the Issue object
    our %eventum;
    my $eventum = $eventum{$uri};
    if ( not $eventum ) {
        require GSG::Eventum;
        # TODO GSG::Eventum has not been publicly released
        $eventum{$uri} = $eventum = GSG::Eventum->new({
            uri      => $uri,
        });
    }

    # GSG::Eventum::Issue is lazy, force an action to verify the issue
    my $issue = $eventum->issue($number);
    $issue = undef if not eval { $issue->summary };
    return $eventum_issue{$number} = $issue;
}


sub transition_state {
    my $self = shift;
    my ($args) = @_;
    $args ||= {};
    $args->{with_time} = 1 unless exists $args->{with_time};
    return "Skipping Eventum changes, as requested by GITC_NO_EVENTUM\n"
        if $ENV{GITC_NO_EVENTUM};
    return "Skipping Eventum changes as configured for this project\n"
        if not project_config()->{'eventum_uri'};

    # validate the arguments
    my $command = $args->{command} || command_name();
    my ($from, $to) = $self->_states( $command, $args->{target} );
    my $message = $args->{message} or die "No eventum message";
    my $issue = exists $args->{issue} ? $args->{issue} :
                                        $self->get_issue(current_branch(), reload => 1);
    return "NOT CHANGING Eventum status: changeset not in Eventum?\n"
        if not $issue;

    # update the Eventum issue
    my $time_format = '%m/%d/%Y';
    $time_format .= ' %I:%M %p' if $args->{with_time};
    $message = (getpwuid $>)[6]   # user's name
                . strftime( " $time_format: $message\n", localtime );
    my ( $rc, $status_exception );
    eval {
        return $rc = $issue->close($message) if $to and $to eq 'CLOSE';
        $issue->postpone_updates;
        $issue->append_internal_comments($message);
        $rc = eval { $issue->transition_status($from, $to) } if $to;
        $status_exception = $@ if $@;
        $issue->update;
        $issue->live_updates;
    };
    die $@ if $@;  # rethrow unexpected exceptions
    if ( $status_exception ) {
        die $status_exception
            if $status_exception !~ m/('[^']+' is not a valid status name)/;
        return "NOT CHANGING Eventum status: $1\n";
    }
    elsif ($rc) {  # success
        return "Changed Eventum status to '$to'\n";
    }
    else {
        return sprintf "NOT CHANGING Eventum status: currently '%s'\n",
            $issue->status;
    }
}


sub issue_state {
    my $self = shift;
    my $issue = shift;
    
    return unless $issue;

    return $issue->status;
}

sub issue_id {
    my $self = shift;
    my $issue = shift;

    return $issue->number;
}

sub issue_changeset_uri {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    my $uri = eval {
        sprintf('%s/view.php?id=%d', $issue->eventum->uri, $issue->number);
    } || '';
    return $uri;
}

sub issue_summary {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return $issue->summary;
}

sub issue_promotion_notes {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return $issue->promotion_notes;
}

sub issue_project {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return $issue->project;
}

sub issue_scheduled_release {
    my $self = shift;
    my $issue = shift;
    return unless $issue;

    return $issue->scheduled_release;
}


sub issue_number {
    my $self = shift;
    my ($changeset_or_issue) = @_;

    return $changeset_or_issue->number if ref $changeset_or_issue;
    
    return $1 if $changeset_or_issue =~ m/\A e (\d+) \w? \z/xms;
    return;
}

1;

__END__

=pod

=head1 NAME

App::Gitc::Its::Eventum - Support for Eventum ITS (Issue Tracking System)

=head1 VERSION

version 0.60

=head1 DESCRIPTION

=head1 METHODS

=head2 get_issue 

Returns a L<GSG::Eventum::Issue> object representing this changeset's Eventum
issue.  If this changeset has no Eventum issue or there was an error locating
it, returns C<undef>.  Normally this will cache the object, and return it
on subsequent calls.  If the C<reload> parameter is set, it will reload the
object and reset the cache.

=head2 transition_state

Change an Eventum issue's status from one value to another.  The following
named arguments are understood:

 message   - required message to put in Eventum's Internal Comments
 issue     - optional GSG::Eventum::Issue object
             (defaults to an Issue for the currently checked out changeset)
 command   - optional name of the command that's changing the status
             (by default, it's inferred from the top-level script)
 with_time - optional boolean defaults to true.
             should a time stamp be added to the message?
 target    - optional name of a promotion target (when $command is 'promote')

The old and new Eventum statuses are specified through the project
configuration file.  They are keyed on the value of the C<command> argument.

=head2 issue_*

These return the correct field based on being passed in an eventum issue object.
Think of it as $issue->*  - Should be replaced with a facade for issues

=head2 issue_state

Returns the current issue 'state' (usually status), this may or may not match the config from/target states

=head2 issue_number

Returns the Eventum issue number for a given changeset name OR given an eventum issue object

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Grant Street Group.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
