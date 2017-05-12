package App::GitHubWebhooks2Ikachan::Events::Push;
use strict;
use warnings;
use utf8;
use String::IRC;

sub call {
    my ($class, $context) = @_;

    my $dat    = $context->dat;
    my $branch = __PACKAGE__->_extract_branch_name($dat);

    my $texts = [];
    for my $commit (@{$dat->{commits} || []}) {
        next if $commit->{distinct} == 0; # to squash duplicated commit

        my $user_name =    $commit->{author}->{username}
                        || $commit->{author}->{name}
                        || $commit->{committer}->{username}
                        || $commit->{committer}->{name};
        (my $commit_message = $commit->{message}) =~ s/\r?\n.*//g;
        my $url = $commit->{url};

        my $main_text = "[push to $branch] $commit_message (\@$user_name)";

        push @$texts, String::IRC->new($main_text)->green . " $url";
    }

    return $texts;
}

sub _extract_branch_name {
    my ($class, $dat) = @_;

    # e.g.
    #   ref: "refs/heads/__BRANCH_NAME__"
    my $branch;
    if (my $ref = $dat->{ref}) {
        $branch = (split qr!/!, $ref)[-1];
    }

    return $branch ? $branch : '';
}

1;

