# A quick Bot::BasicBot::Pluggable module to announce new/changed issues
# and soon, pushes. 
#
# David Precious <davidp@preshweb.co.uk>
 
package Bot::BasicBot::Pluggable::Module::GitHub::Announce;
use strict;
use Bot::BasicBot::Pluggable::Module::GitHub;
use base 'Bot::BasicBot::Pluggable::Module::GitHub';
use JSON;

our $VERSION = 0.02;
 
sub help {
    return <<HELPMSG;
Announce new/changed issues and pull requests, and, soon, pushes. 
HELPMSG
}


sub tick {
    my $self = shift;

    my $issue_state_file = 'last-issues-state.json';
    
    my $seconds_between_checks = $self->get('poll_issues_interval') || 60 * 5;
    return if time - $self->get('last_issues_poll') < $seconds_between_checks;
    $self->set('last_issues_poll', time);

    # Grab details of the issues we know about already:
    # Have to handle storing & loading old issue state myself - I don't know
    # why, but the bot storage doesn't want to work for this.
    open my $fh, '<', $issue_state_file
        or die "Failed to open $issue_state_file - $!";
    my $json;
    { local $/; $json = <$fh> }
    close $fh;
    my $seen_issues = $json ? JSON::from_json($json) : {};


    # OK, for each channel, pull details of all issues from the API, and look
    # for changes
    my $channels_and_projects = $self->channels_and_projects;
    channel:
    for my $channel (keys %$channels_and_projects) {
        my $project = $channels_and_projects->{$channel};
        my %notifications;
        warn "Looking for issues for $project for $channel";

        my $ng = $self->ng($project) or next channel;

        my $issues = $ng->issue->list('open');

        # Go through all currently-open issues and look for new/reopened ones
        for my $issue (@$issues) {
            my $issuenum = $issue->{number};
            my $details = {
                title      => $issue->{title},
                url        => $issue->{html_url},
                created_by => $issue->{user},
            };

            if (my $existing = $seen_issues->{$project}{$issuenum}) {
                if ($existing->{state} eq 'closed') {
                    # It was closed before, but is now in the open feed, so it's
                    # been re-opened
                    push @{ $notifications{reopened} }, 
                        [ $issuenum, $details ];
                    $existing->{state} = 'open';
                }
            } else {
                # A new issue we haven't seen before
                push @{ $notifications{opened} },
                    [ $issuenum, $details ];
                $seen_issues->{$project}{$issuenum} = {
                    state => 'open',
                    details => $details,
                };
            }
        }

        # Now, go through ones we already know about - if we knew about them,
        # and they were open, but weren't in the list of open issues we fetched
        # above, they must now be closed
        for my $issuenum (keys %{ $seen_issues->{$project} }) {
            my $existing = $seen_issues->{$project}{$issuenum};
            my $current = grep { 
                $_->{number} == $issuenum 
            } @$issues;

            if ($existing->{state} eq 'open' && !$current) {
                # It was open before, but isn't in the list now - it must have
                # been closed.
                push @{ $notifications{closed} },
                    [ $issuenum, $existing->{details} ];
                $existing->{state} = 'closed';
            }
        }

        # Announce any changes
        for my $type (keys %notifications) {
            my $s = scalar $notifications{$type} > 1 ? 's':'';

            $self->say(
                channel => $channel,
                body => "Issue$s $type : "
                    . join ', ', map { 
                        sprintf "%d (%s) by %s : %s", 
                        $_->[0], # issue number
                        @{$_->[1]}{qw(title created_by url)}
                    } @{ $notifications{$type} }
            );
        }
    }

    my $store_json = JSON::to_json($seen_issues);
    # Store the updated issue details:
    open my $storefh, '>', $issue_state_file
        or die "Failed to write to $issue_state_file - $!";
    print {$storefh} $store_json;
    close $storefh;
    return;

}

