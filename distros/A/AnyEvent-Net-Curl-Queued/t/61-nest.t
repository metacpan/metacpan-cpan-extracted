#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;
use List::Util qw(shuffle);

use AnyEvent::Net::Curl::Queued;
use AnyEvent::Net::Curl::Queued::Easy;
use Test::HTTP::AnyEvent::Server;

my $server = Test::HTTP::AnyEvent::Server->new;

my @q = map { AnyEvent::Net::Curl::Queued->new(allow_dups => 1, max => 2) } 1 .. 5;

my $n = 10;
for my $i (1 .. $n) {
    for my $q (shuffle @q) {
        $q->prepend(sub {
            AnyEvent::Net::Curl::Queued::Easy->new(
                initial_url => URI->new($server->uri . qq(echo/head)),
                opts        => {
                    postfields  => qq({"i":$i}),
                },
                on_finish   => sub {
                    my ($self, $result) = @_;
                    ok($result == 0, 'got CURLE_OK');
                    ok(!$self->has_error, "libcurl message: '$result'");
                },
            )
        });
    }
}

$_->wait for shuffle @q;
done_testing((scalar @q) * $n * 2);
