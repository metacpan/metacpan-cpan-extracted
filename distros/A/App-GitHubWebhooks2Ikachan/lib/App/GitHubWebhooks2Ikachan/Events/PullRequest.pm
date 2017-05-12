package App::GitHubWebhooks2Ikachan::Events::PullRequest;
use strict;
use warnings;
use utf8;
use String::IRC;

sub call {
    my ($class, $context) = @_;

    my $pull_request = $context->dat->{pull_request};

    my $pull_request_title = $pull_request->{title};
    my $user_name = $pull_request->{user}->{login};
    my $url = $pull_request->{html_url};

    my $action = $context->dat->{action};
    my $subscribe_actions = $context->req->param('pull_request');
    if (
        !$subscribe_actions || # Allow all actions
        grep { $_ eq $action } split(/,/, $subscribe_actions) # Filter by specified actions
    ) {
        my $main_text = "[pull request $action (#$pull_request->{number})] $pull_request_title (\@$user_name)";

        return String::IRC->new($main_text)->green . " $url";
    }

    return; # Not match any actions
}

1;

