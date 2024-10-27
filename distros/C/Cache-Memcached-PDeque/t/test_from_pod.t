#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More tests => 40;

my $dq = Cache::Memcached::PDeque->new( name => 'aName', max_prio => 2 );

# Add and remove some elements
ok $dq->push('a');
ok $dq->unshift('b');
ok $dq->push('c');

is $dq->pop(), 'c';
is $dq->pop(), 'a';
is $dq->shift(), 'b';

is $dq->size, 0;

# Remove all elements
ok $dq->push(1, 'l1'); # ('l1')
ok $dq->push(1, 'l2'); # ('l1','l2')
ok $dq->push(2, 'h1'); # ('h1','l1','l1')
is $dq->size, 3;

ok $dq->clear;
is $dq->size, 0;

# Make use of priorities
ok $dq->push(1, 'l1'); # ('l1')
ok $dq->push(2, 'h1'); # ('h1','l1')

is $dq->size,    2, 'Two elements, but:';
is $dq->size(1), 1, 'Only 1 element with priority 1';
is $dq->size(2), 1, 'Only 1 element with priority 2';

is $dq->shift(), 'h1';
is $dq->shift(), 'l1';

is $dq->size, 0;

# Make use of priorities for adding and removing
ok $dq->push(1, 'l1'); # ('l1')
ok $dq->push(2, 'h1'); # ('h1')

is $dq->shift(1), 'l1';
is $dq->shift(1), undef, 'undef'; # No elements with priority 1
is $dq->shift(2), 'h1';

is $dq->size, 0;

# Complex structures are supported
my @list = ( 1, 'a', 2, 'b', 3, 'c' );
ok $dq->push(\@list);
my $href = $dq->pop;
map { is shift @{$href}, $_, "test $_" } @list;

my $dqr = Cache::Memcached::PDeque->new( name => 'anotherName', max_prio => 2, prioritizer => \&remainder ); 

sub remainder {
my $element = shift;
my $prio = $element % 2; # This is either 0 or 1
return $prio+1;          # This is 1 or 2, a valid priority
}

ok $dqr->push(1); # ( 1 )
ok $dqr->push(2); # ( 1 2 )
ok $dqr->push(3); # ( 1 3 2 )
is $dqr->shift, 1;
is $dqr->shift, 3;
is $dqr->shift, 2;

# Keep the flush here as a quick way to clear memcached when a test
# fails and we need te start from scratch
$dq->_flush;
