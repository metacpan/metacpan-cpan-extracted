#!perl

use strict;
use warnings;
use utf8;
use Plack::Request;
use App::GitHubWebhooks2Ikachan;

use Test::More;

my $g2i = App::GitHubWebhooks2Ikachan->new({ikachan_url => 'http://example.com'});

subtest 'Missing channel name' => sub {
    my $req = Plack::Request->new({
        PATH_INFO => "/",
    });

    my $got = $g2i->respond_to_ikachan($req);

    is $got->[0], 400;
    is $got->[2]->[0], 'Missing channel name';
};

subtest 'Payload is nothing' => sub {
    my $req = Plack::Request->new({
        PATH_INFO => "/%23foobar",
    });

    my $got = $g2i->respond_to_ikachan($req);

    is $got->[0], 400;
    is $got->[2]->[0], 'Payload is nothing';
};

done_testing;

