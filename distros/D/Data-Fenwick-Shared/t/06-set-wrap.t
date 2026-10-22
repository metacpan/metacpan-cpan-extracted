use strict;
use warnings;
use Test::More;
use Data::Fenwick::Shared;

my $min = -9223372036854775807 - 1;
my $max = 9223372036854775807;
for my $constructor (qw(new new_range)) {
    subtest $constructor => sub {
        my $tree = Data::Fenwick::Shared->$constructor(undef, 4);
        is $tree->set(1, $min), 0, 'set returns the previous value';
        is $tree->set(1, $max), $min, 'set spans the signed range';
        is $tree->point(1), $max, 'maximum value is retained';
        is $tree->set(1, $min), $max, 'set spans the signed range in reverse';
        is $tree->point(1), $min, 'minimum value is retained';
        $tree->set(3, -1);
        is $tree->prefix(3), $max, 'prefix accumulation wraps';
        is $tree->range(3, 3), -1, 'range subtraction wraps';
        if ($constructor eq 'new') {
            my $other = Data::Fenwick::Shared->new(undef, 4);
            $other->set(1, -1);
            $tree->merge($other);
            is $tree->point(1), $max, 'merge wraps';
            $tree->update(1, 1);
            is $tree->point(1), $min, 'point update wraps';
        } else {
            $tree->clear;
            $tree->range_add(2, 3, $min);
            is $tree->point(2), $min, 'range update accepts the minimum delta';
            is $tree->point(3), $min, 'range update covers its full interval';
            is $tree->point(4), 0, 'negated minimum delta restores the interval boundary';
            is $tree->total, 0, 'range weights and sums wrap';
            $tree->range_add(2, 3, -1);
            is $tree->point(2), $max, 'range update wraps in reverse';
            is $tree->total, -2, 'wrapped range total stays exact';
        }
    };
}
done_testing;
