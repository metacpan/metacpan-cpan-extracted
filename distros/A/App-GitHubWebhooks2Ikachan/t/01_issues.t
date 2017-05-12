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

subtest 'issue opened' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'issues', 'opened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "issues",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'issues',
            issues    => 'opened',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[issue opened \(#13\)\] This is new issue \(\@moznion\)\17 https://github.com/moznion/sandbox/issues/13!;
};

subtest 'issue closed' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'issues', 'closed.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "issues",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'issues',
            issues    => 'closed',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[issue closed \(#13\)\] This is new issue \(\@moznion\)\17 https://github.com/moznion/sandbox/issues/13!;
};

subtest 'issue reopened' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'issues', 'reopened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "issues",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'issues',
            issues    => 'reopened',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[issue reopened \(#13\)\] This is new issue \(\@moznion\)\17 https://github.com/moznion/sandbox/issues/13!;
};

subtest 'subscribe all actions' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'issues', 'opened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "issues",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'issues',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!\[INFO\] POST $channel, \00303\[issue opened \(#13\)\] This is new issue \(\@moznion\)\17 https://github.com/moznion/sandbox/issues/13!;
};

subtest 'not subscribe action' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'issues', 'opened.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "issues",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'issues',
            issues    => 'close',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    ok !$got;
};

done_testing;
