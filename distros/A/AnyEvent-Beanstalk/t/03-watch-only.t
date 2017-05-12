#!/usr/bin/env perl

use AnyEvent::Beanstalk;
use Test::More;
use Test::Deep;
use Test::Warnings;
use t::start_server;

my $c = get_client();

plan tests => 7 + 1;

my $ts = $c->list_tubes_watched()->recv;
cmp_deeply($ts, bag('default'));

cmp_deeply([$c->watching], bag('default'));

$c->watch_only('default')->recv;
cmp_deeply([$c->watching], bag('default'));

$c->watch_only('t1')->recv;
cmp_deeply([$c->watching], bag('t1'));

$c->watch_only('t1', 't2')->recv;
cmp_deeply([$c->watching], bag('t1', 't2'));

$c->watch_only('t1', 't2')->recv;
cmp_deeply([$c->watching], bag('t1', 't2'));

my @r = $c->watch_only('t3', 't4')->recv;
cmp_deeply([$c->watching], bag('t3', 't4'));

done_testing;


