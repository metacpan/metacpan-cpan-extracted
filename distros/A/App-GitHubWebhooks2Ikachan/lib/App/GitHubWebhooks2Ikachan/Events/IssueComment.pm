package App::GitHubWebhooks2Ikachan::Events::IssueComment;
use strict;
use warnings;
use utf8;
use String::IRC;

sub call {
    my ($class, $context) = @_;

    my $comment = $context->dat->{comment};

    (my $comment_body = $comment->{body}) =~ s/\r?\n.*//g;
    my $user_name    = $comment->{user}->{login};
    my $url = $comment->{html_url};

    my $issue = $context->dat->{issue};
    my $issue_number = $issue->{number};

    my $main_text = "[comment (#$issue_number)] $comment_body (\@$user_name)";
    return String::IRC->new($main_text)->green . " $url";
}

1;

