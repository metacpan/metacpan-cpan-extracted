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

my $q = AnyEvent::Net::Curl::Queued->new;
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

ok($q->max      == 4, 'default max()');
ok($q->timeout  == 60.0, 'default timeout()');

isa_ok($q->share, 'Net::Curl::Share');
isa_ok($q->stats, 'AnyEvent::Net::Curl::Queued::Stats');

$q->append(
    AnyEvent::Net::Curl::Queued::Easy->new($server->uri . 'echo/head#' . rand)
) for 1 .. 10; # test deduplication by URL

$q->wait;

ok($q->completed == 1, 'single GET');

done_testing(12);
