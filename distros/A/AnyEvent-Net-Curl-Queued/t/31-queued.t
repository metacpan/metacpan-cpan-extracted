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

my $server = Test::HTTP::AnyEvent::Server->new;
isa_ok($server, 'Test::HTTP::AnyEvent::Server');

my $q = AnyEvent::Net::Curl::Queued->new(5);
isa_ok($q, qw(AnyEvent::Net::Curl::Queued));

can_ok($q, qw(
    add
    append
    completed
    count
    cv
    dequeue
    empty
    max
    multi
    prepend
    queue
    queue_push
    queue_unshift
    share
    start
    stats
    timeout
    wait
));

ok($q->max      == 5, 'non-default max()');
ok($q->timeout  == 60.0, 'default timeout()');

isa_ok($q->share, 'Net::Curl::Share');
isa_ok($q->stats, 'AnyEvent::Net::Curl::Queued::Stats');

for my $method (qw(append prepend)) {
    for my $i (1 .. $q->max) {
        $q->$method(
            sub {
                AnyEvent::Net::Curl::Queued::Easy->new($server->uri . 'repeat/' . ($i * 1024) . '/' . $method)
            }
        );
    }
}

$q->wait;

ok($q->completed == $q->max * 2, 'simple GET');

done_testing(12);
