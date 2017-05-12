use strict;
use Test::More;

use_ok $_ for qw(
    App::GitHubWebhooks2Ikachan
    App::GitHubWebhooks2Ikachan::Events
    App::GitHubWebhooks2Ikachan::Events::IssueComment
    App::GitHubWebhooks2Ikachan::Events::Issues
    App::GitHubWebhooks2Ikachan::Events::PullRequest
    App::GitHubWebhooks2Ikachan::Events::Push
);

done_testing;

