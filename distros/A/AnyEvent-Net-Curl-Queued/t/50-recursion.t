#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use_ok('AnyEvent::Net::Curl::Queued');
use_ok('AnyEvent::Net::Curl::Queued::Easy');
use_ok('AnyEvent::Net::Curl::Queued::Stats');
use_ok('Test::HTTP::AnyEvent::Server');

use lib qw(t);
use_ok(q(Recursioner));

my $server = Test::HTTP::AnyEvent::Server->new;
isa_ok($server, 'Test::HTTP::AnyEvent::Server');

my $q = AnyEvent::Net::Curl::Queued->new;
isa_ok($q, qw(AnyEvent::Net::Curl::Queued));

$q->append(
    sub {
        Recursioner->new(
            initial_url => $server->uri . 'repeat/6/aaaaa',
            cb          => sub {
                my ($self, $result) = @_;

                isa_ok($self, qw(Recursioner));
                ok($result == 0, 'got CURLE_OK for ' . $self->final_url);
                ok(!$self->has_error, "libcurl message: '$result'");
            },
        )
    }
);

$q->wait;

done_testing 157;
