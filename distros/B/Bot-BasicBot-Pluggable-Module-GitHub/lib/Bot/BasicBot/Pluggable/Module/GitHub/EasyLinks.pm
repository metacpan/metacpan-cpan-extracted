# A quick Bot::BasicBot::Pluggable module to provide easy links when someone
# mentions an issue / pull request / commit.
#
# David Precious <davidp@preshweb.co.uk>

package Bot::BasicBot::Pluggable::Module::GitHub::EasyLinks;
use strict;
use Bot::BasicBot::Pluggable::Module::GitHub;
use base 'Bot::BasicBot::Pluggable::Module::GitHub';
use URI::Title;

sub help {
    return <<HELPMSG;
Provide convenient links to GitHub issues/pull requests/commits etc.

If someone says e.g. "Issue 42", the bot will helpfully provide an URL to view
that issue directly.

The project these relate to must be configured using the vars module to set the
'default project' setting (or directly set user_default_project in the bot's
store).

HELPMSG
}


sub said {
    my ($self, $mess, $pri) = @_;
    
    return unless $pri == 2;


    # Loop through matching things in the message body, assembling quick links
    # ready to return.
    my @return;
    match:
    while ($mess->{body} =~ m{ 
        (?:  
            \b
            # "Issue 42", "PR 42" or "Pull Request 42"
            (?<thing> (?:issue|gh|pr|pull request) ) 
            (?:\s+|-)?
            (?<num> \d+)
        |                
            # Or a commit SHA
            (?<sha> [0-9a-f]{6,})
        )    
        # Possibly with a specific project repo ("user/repo") appeneded
        (?: \s* \@ \s* (?<project> \S+/\S+) )?
        }gxi
    ) {

        my $project = $+{project} || $self->github_project($mess->{channel});
        return unless $project;

        # Get the Net::GitHub::V2 object we'll be using.  (If we don't get one,
        # for some reason, we can't do anything useful.)
        my $ng = $self->ng($project) or return;

        # First, extract what kind of thing we're looking at, and normalise it a
        # little, then go on to handle it.
        my $thing    = $+{thing};
        my $thingnum = $+{num};

        if ($+{sha}) {
            $thing    = 'commit';
            $thingnum = $+{sha};
        }

        warn "OK, about to try to handle $thing $thingnum for $project";

        # Right, handle it in the approriate way
        if ($thing =~ /Issue|GH/i) {
            warn "Handling issue $thingnum";
            my $issue = $ng->issue->view($thingnum);
            if (exists $issue->{error}) {
                push @return, $issue->{error};
                next match;
            }
            push @return, sprintf "Issue %d (%s) - %s",
                $thingnum,
                $issue->{title},
                $issue->{html_url};
        }

        # Similarly, pull requests:
        if ($thing =~ /(?:pr|pull request)/i) {
            warn "Handling pull request $thingnum";
            # TODO: send a pull request to add support for fetching details of
            # pull requests to Net::GitHub::V2, so we can handle PRs on private
            # repos appropriately.
            my $pull_url = "https://github.com/$project/pull/$thingnum";
            my $title = URI::Title::title($pull_url);
            push @return, "Pull request $thingnum ($title) - $pull_url";
        }

        # If it was a commit:
        if ($thing eq 'commit') {
            warn "Handling commit $thingnum";
            my $commit = $ng->commit->show($thingnum);
            if ($commit && !exists $commit->{error}) {
                my $title = ( split /\n+/, $commit->{message} )[0];
                my $url = $commit->{url};
                
                # Currently, the URL given doesn't include the host, but that
                # might perhaps change in future, so play it safe:
                $url = "https://github.com$url" unless $url =~ /^http/;
                push @return, sprintf "Commit $thingnum (%s) - %s",
                    $title,
                    $url;
            } else {
                # We purposefully don't show a message on IRC here, as we guess
                # what might be a SHA, so we could be annoying saying that we
                # didn't match a commit when someone said a word that just
                # happened to look like it could be the start of a SHA.
                warn "No commit details for $thingnum \@ $project/$thingnum";
            }
        }
    }
    
    return join "\n", @return;
}





1;

