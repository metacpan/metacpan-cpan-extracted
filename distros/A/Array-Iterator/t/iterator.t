#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 99;

BEGIN {
    use_ok('Array::Iterator')
};

my @control = (1 .. 5);

can_ok("Array::Iterator", 'new');
my $iterator = Array::Iterator->new(@control);

isa_ok($iterator, 'Array::Iterator');

# check my private methods
can_ok($iterator, '_init');

# check my protected methods
can_ok($iterator, '_getItem');
can_ok($iterator, '_current_index');
can_ok($iterator, '_iteratee');

# check out public methods
can_ok($iterator, 'hasNext');
can_ok($iterator, 'has_next');
can_ok($iterator, 'next');
can_ok($iterator, 'peek');
can_ok($iterator, 'getNext');
can_ok($iterator, 'get_next');
can_ok($iterator, 'current');
can_ok($iterator, 'currentIndex');
can_ok($iterator, 'current_index');
can_ok($iterator, 'getLength');
can_ok($iterator, 'get_length');
can_ok($iterator, 'iterated');

# now check the behavior

ok(!$iterator->iterated(), '... not yet iterated, iterated() is false');

cmp_ok($iterator->getLength(), '==', 5, '... got the right length');

for (my $i = 0; $i < scalar @control; $i++) {
    # we should still have another one
    ok($iterator->hasNext(), '... we have more elements');
    # and out iterator peek should match our control index
    # (since we have not incremented the iterator's counter)
    unless ($i >= (scalar(@control))) {
        cmp_ok($iterator->peek(), '==', $control[$i],
               '... our control should match our iterator->peek');
    }
    else {
        ok(!defined($iterator->peek()), '... this should return undef now');
    }
    # and out iterator should match our control
    cmp_ok($iterator->next(), '==', $control[$i],
           '... our control should match our iterator->next');
    # and out iterator peek should match our control + 1 (now that we have incremented the counter)
    unless (($i + 1) >= (scalar(@control))) {
        cmp_ok($iterator->peek(), '==', $control[$i + 1],
               '... our control should match our iterator->peek');
    }
    else {
        ok(!defined($iterator->peek()), '... this should return undef now');
    }
}

ok($iterator->iterated(), '... has been iterated, iterated() is true');

# we should have no more
ok(!$iterator->hasNext(), '... we should have no more');

# now use an array ref in the constructor
# and try using it in this style loop
for (my $i = Array::Iterator->new(\@control); $i->hasNext(); $i->next()) {
	cmp_ok($i->current(), '==', $control[$i->currentIndex()], '... these should be equal');
}

my $iterator2 = Array::Iterator->new(@control);
my @acc;
push @acc, => $iterator2->next() while $iterator2->hasNext();

# our accumulation and control should be the same
ok(eq_array(\@acc, \@control), '... these arrays should be equal');

# we should have no more
ok(!$iterator2->hasNext(), '... we should have no more');

{
    my $iterator3 = Array::Iterator->new(\@control);

    my $current;
    while ($current = $iterator3->getNext()) {
        if ($iterator3->currentIndex() + 1 < (scalar(@control))) {
            cmp_ok($iterator3->peek(), '==', $control[$iterator3->currentIndex() + 1], '... these should be equal (peek & currentIndex + 1)');
        }
        else {
            ok(!defined($iterator3->peek()), '... this should return undef now');
        }
        cmp_ok($current, '==', $control[$iterator3->currentIndex()], '... these should be equal (getNext)');
        cmp_ok($current, '==', $iterator3->current(), '... these should be equal (getNext)');
    }

    ok(!defined($iterator3->getNext()), '... we should get undef');

    # we should have no more
    ok(!$iterator3->hasNext(), '... we should have no more');
}

{
    # verify that we can pass a hash ref as well
    my $iterator4 = Array::Iterator->new({ __array__ => \@control });
    isa_ok($iterator, 'Array::Iterator');

    my $current;
    while ($current = $iterator4->getNext()) {
        if ($iterator4->currentIndex() + 1 < (scalar(@control))) {
            cmp_ok($iterator4->peek(), '==', $control[$iterator4->currentIndex() + 1], '... these should be equal (peek & currentIndex + 1)');
        }
        else {
            ok(!defined($iterator4->peek()), '... this should return undef now');
        }
        cmp_ok($current, '==', $control[$iterator4->currentIndex()], '... these should be equal (getNext)');
        cmp_ok($current, '==', $iterator4->current(), '... these should be equal (getNext)');
    }

    ok(!defined($iterator4->getNext()), '... we should get undef');

    # we should have no more
    ok(!$iterator4->hasNext(), '... we should have no more');
}

{
    # check arbitrary position lookups
    my $iterator5 = Array::Iterator->new(@control);

    # when not iterated()
    ok($iterator5->has_next,     '... we should have next element');
    ok($iterator5->has_next(1),  '... should be the same as has_next()');
    ok($iterator5->has_next(2),  '... we should have 2nd next element');
    ok($iterator5->has_next(5),  '... we should have 5th next element');
    ok(!$iterator5->has_next(6), '... we should not have 6th next element');

    cmp_ok($iterator5->peek(1), '==', $iterator5->peek, '... should be the same as peek()');
    cmp_ok($iterator5->peek(2), '==', 2,                '... we should get 2nd next element');
    cmp_ok($iterator5->peek(5), '==', 5,                '... we should get 5th next element');

    ok(!defined($iterator5->peek(6)), '... peek() outside of the bounds should return undef');

    $iterator5->next;

    # when iterated()
    ok($iterator5->has_next(4),       '... we should have 4th next element after iterating');
    ok(!$iterator5->has_next(5),      '... we should not have 5th next element after iterating');

    cmp_ok($iterator5->peek(1), '==', $iterator5->peek, '... should be the same as peek() after iterating');
    cmp_ok($iterator5->peek(2), '==', 3,                '... we should get 2nd next element after iterating');

    ok(!defined($iterator5->peek(5)), '... peek() outside of the bounds should return undef after iterating');
}
