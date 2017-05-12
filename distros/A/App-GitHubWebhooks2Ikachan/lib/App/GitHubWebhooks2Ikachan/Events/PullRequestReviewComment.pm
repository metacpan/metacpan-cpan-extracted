package App::GitHubWebhooks2Ikachan::Events::PullRequestReviewComment;
use strict;
use warnings;
use utf8;
use String::IRC;

sub call {
    my ($class, $context) = @_;

    my $comment = $context->dat->{comment};

    (my $comment_body = $comment->{body}) =~ s/\r?\n.*//g;
    my $user_name = $comment->{user}->{login};
    my $url = $comment->{html_url};

    my ($pull_request_number) = $comment->{pull_request_url} =~ m!/(\d+)\Z!;

    my $main_text = "[review comment (#$pull_request_number)] $comment_body (\@$user_name)";
    return String::IRC->new($main_text)->green . " $url";
}

1;

