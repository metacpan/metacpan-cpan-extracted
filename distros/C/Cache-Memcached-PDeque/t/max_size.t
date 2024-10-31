#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More tests => 18;

my $dq = Cache::Memcached::PDeque->new( name => 'max', max_size => 2 );

ok($dq->_check);
is($dq->max_size, 2);

# Adding two elements must be ok
is($dq->size, scalar @array);
ok($dq->push('a')); push @array, 'a';
is($dq->size, scalar @array);
ok($dq->push('b')); push @array, 'b';
is($dq->size, scalar @array);

# Adding another element must fail
is($dq->push('c'), 0);
is($dq->size, scalar @array);

# Increase the max size and add another element
$dq->max_size(3);
is($dq->max_size, 3);
is($dq->size, scalar @array);
ok($dq->push('d')); push @array, 'd';
is($dq->size, scalar @array);

# Decreasing the maximum size does not change any elements
$dq->max_size(1);
is($dq->max_size, 1);
is($dq->size, scalar @array);

# But prevents adding elements
is($dq->push('c'), 0);
is($dq->size, scalar @array);

# Test if everything is as we expect; use a quick oneliner
# to construct a list with whatever is currently in $dq.
my @dq;
$dq->foreach( sub { my ($e, $p) = @_; push @{$p}, $e }, \@dq);
is_deeply(\@dq, \@array);

# Keep the flush here as a quick way to clear memcached when a test
# fails and we need te start from scratch
$dq->_flush;
