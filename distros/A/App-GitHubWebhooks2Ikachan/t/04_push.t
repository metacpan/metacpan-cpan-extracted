#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture capture_stderr/;
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

subtest 'commits' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'push', 'commits.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "push",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'push',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    my @commits = split /\n/, $got;

    like $commits[0], qr!POST $channel, \00303\[push to master\] Commit1 \(\@moznion\)\17 https://github\.com/moznion/sandbox/commit/b4da12df1bc19d2b20d7ab8a11fe9a4413ddf509!;
    like $commits[1], qr!POST $channel, \00303\[push to master\] Commit2 \(\@moznion\)\17 https://github\.com/moznion/sandbox/commit/e2e64cea713dbfb574f1ace80a4be6c55f98433d!;
};

subtest 'merge commit' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'push', 'merge.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "push",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'push',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!POST $channel, \00303\[push to master\] Merge pull request #15 from moznion/new_pull_request \(\@moznion\)\17 https://github\.com/moznion/sandbox/commit/d2427a9b4ffbf5277cfe4229f22b0337146b77d3!;
};

done_testing;
