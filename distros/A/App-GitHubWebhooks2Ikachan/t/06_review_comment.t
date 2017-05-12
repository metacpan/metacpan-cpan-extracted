#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture_stderr/;
use File::Spec::Functions qw/catfile/;
use FindBin;
use Hash::MultiValue;
use Plack::Request;

use App::GitHubWebhooks2Ikachan;

use Test::More;

my $g2i = App::GitHubWebhooks2Ikachan->new({
    ikachan_url => 'http://example.com',
});
my $channel = 'foo';

subtest 'commit comment' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'review_comment', 'created.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request_review_comment",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'pull_request_review_comment',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    my @commits = split /\n/, $got;

    like $commits[0], qr%POST foo, \00303\[review comment \(#18\)\] Hello \(\@moznion\)\17 https://github\.com/moznion/sandbox/pull/18#discussion_r11326210%;
};

done_testing;

