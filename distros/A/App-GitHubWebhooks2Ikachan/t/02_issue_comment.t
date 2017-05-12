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

subtest 'comment created' => sub {
    open my $fh, '<', catfile($FindBin::Bin, 'resources', 'issue_comment', 'created.json');
    my $payload = do { local $/; <$fh>; };

    my $req = Plack::Request->new({
        HTTP_X_GITHUB_EVENT => "issue_comment",
        PATH_INFO => "/$channel",
        'plack.request.body' => Hash::MultiValue->new(
            payload   => $payload,
            subscribe => 'issue_comment',
        ),
    });

    my $got = capture_stderr{ $g2i->respond_to_ikachan($req) };
    like $got, qr!POST $channel, \00303\[comment \(#13\)\] foobar \(\@moznion\)\17 https://github\.com/moznion/sandbox/issues/13#issuecomment-37093289!;
};

done_testing;
