#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More tests => 12;

my $dq = Cache::Memcached::PDeque->new( name => 'foreach', max_prio => 2 );

ok($dq->push(1,'1a'));
ok($dq->push(1,'1b'));
ok($dq->push(2,'2a'));
ok($dq->push(2,'2b'));

is($dq->size, 4);

is($dq->front, '2a');
is($dq->back,  '1b');

is($dq->front(1), '1a');
is($dq->front(2), '2a');

is($dq->back(1),  '1b');
is($dq->back(2),  '2b');

is($dq->size, 4);

$dq->_flush;
