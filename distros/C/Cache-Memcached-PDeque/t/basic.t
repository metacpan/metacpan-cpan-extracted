#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More tests => 27;

my $dq = Cache::Memcached::PDeque->new( name => 'basic', max_prio => 2 );
my @array;

#$dq->priority(4);
ok($dq->_check);

is($dq->size, scalar @array);

# (a)
ok($dq->push('a')); push @array, 'a';
ok($dq->_check);
is($dq->size, scalar @array);

# (a,z)
ok($dq->push('z')); push @array, 'z';
ok($dq->_check);
is($dq->size, scalar @array);

# (a,z,b)
ok($dq->push('b')); push @array, 'b';
ok($dq->_check);
is($dq->size, scalar @array);

# (z,b)
ok((grep { $_ eq 'a' } shift @array, $dq->shift), "Testing for 'a'");
ok($dq->_check);
is($dq->size, scalar @array);

# (c,z,b)
ok($dq->unshift('c')); unshift @array, 'c';
ok($dq->_check);
is($dq->size, scalar @array);

# (c,z)
ok((grep { $_ eq 'b' } pop @array, $dq->pop), "Testing for 'b'");
ok($dq->_check);
is($dq->size, scalar @array);

ok((grep { $_ eq 'z' } pop @array, $dq->pop), "Testing for 'z'");
ok($dq->_check);
is($dq->size, scalar @array);

ok((grep { $_ eq 'c' } shift @array, $dq->shift), "Testing for 'c'");
ok($dq->_check);
is($dq->size, scalar @array);

is($dq->size,0);

# Keep the flush here as a quick way to clear memcached when a test
# fails and we need te start from scratch
$dq->_flush;
