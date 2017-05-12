package App::GitHubWebhooks2Ikachan::Events::CommitComment;
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

    my ($commit_id) = $comment->{commit_id} =~ /\A(.{7})/;

    my $main_text = "[comment ($commit_id)] $comment_body (\@$user_name)";
    return String::IRC->new($main_text)->green . " $url";
}

1;

