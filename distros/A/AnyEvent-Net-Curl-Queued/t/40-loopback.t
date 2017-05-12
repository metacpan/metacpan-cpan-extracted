#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use_ok('AnyEvent::Net::Curl::Queued');
use_ok('Test::HTTP::AnyEvent::Server');

use lib qw(t);
use_ok(q(Loopbacker));

my $server = Test::HTTP::AnyEvent::Server->new;
isa_ok($server, 'Test::HTTP::AnyEvent::Server');

my $q = AnyEvent::Net::Curl::Queued->new({ allow_dups => 1 });
isa_ok($q, 'AnyEvent::Net::Curl::Queued');

can_ok($q, qw(append prepend cv));

my $n = 50;
for my $i (1 .. $n) {
    my $url = $server->uri . 'echo/head';
    $q->append(sub {
        Loopbacker->new(
            initial_url => $url,
            post        => "i=$i",
            cb          => sub {
                my ($self, $result) = @_;

                isa_ok($self, qw(Loopbacker));

                can_ok($self, qw(
                    data
                    final_url
                    has_error
                    header
                    initial_url
                ));

                ok($self->final_url eq $url, 'initial/final URLs match');
                ok($result == 0, 'got CURLE_OK');
                ok(!$self->has_error, "libcurl message: '$result'");

                like(${$self->data}, qr{^POST\s+/echo/head\s+HTTP/1\.[01]}ix, 'got data: ' . ${$self->data});
            },
        )
    });
}
$q->cv->wait;

done_testing(6 + 6 * $n);
