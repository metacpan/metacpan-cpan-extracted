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
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'commit_comment', 'created.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "commit_comment",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'commit_comment',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    my @commits = split /\n/, $got;

    like $commits[0], qr%POST foo, \00303\[comment \(adfb4f5\)\] Hello! \(\@moznion\)\17 https://github\.com/moznion/sandbox/commit/adfb4f5fa983e4fc5d5559d6b653284ca03f296d#commitcomment-5920929%;
};

done_testing;

