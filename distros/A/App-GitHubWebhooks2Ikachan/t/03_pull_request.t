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

subtest 'pull request opened' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'pull_request', 'opened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload      => $payload,
            subscribe    => 'pull_request',
            pull_request => 'opened',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[pull request opened \(#15\)\] New Pull Request \(\@moznion\)\17 https://github.com/moznion/sandbox/pull/15!;
};

subtest 'pull request closed' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'pull_request', 'closed.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload      => $payload,
            subscribe    => 'pull_request',
            pull_request => 'closed',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[pull request closed \(#15\)\] New Pull Request \(\@moznion\)\17 https://github.com/moznion/sandbox/pull/15!;
};

subtest 'issue reopened' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'pull_request', 'reopened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload      => $payload,
            subscribe    => 'pull_request',
            pull_request => 'reopened',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[pull request reopened \(#15\)\] New Pull Request \(\@moznion\)\17 https://github.com/moznion/sandbox/pull/15!;
};

subtest 'issue synchronize' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'pull_request', 'synchronize.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload      => $payload,
            subscribe    => 'pull_request',
            pull_request => 'synchronize',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[pull request synchronize \(#15\)\] New Pull Request \(\@moznion\)\17 https://github.com/moznion/sandbox/pull/15!;
};

subtest 'subscribe all actions' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'pull_request', 'opened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[pull request opened \(#15\)\] New Pull Request \(\@moznion\)\17 https://github.com/moznion/sandbox/pull/15!;
};

subtest 'not subscribe action' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'pull_request', 'opened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "pull_request",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload      => $payload,
            subscribe    => 'pull_request',
            pull_request => 'close',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    ok !$got;
};

done_testing;
