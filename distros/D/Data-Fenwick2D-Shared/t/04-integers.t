use strict;
use warnings;
use Test::More;
use Data::Fenwick2D::Shared;

my $max = 9_223_372_036_854_775_807;
my $min = -$max - 1;
my $f = Data::Fenwick2D::Shared->new(undef, 3, 3);

$f->update(1, 1, $max);
$f->update(1, 1, 1);
is $f->point(1, 1), $min, 'update wraps from maximum to minimum';
$f->update(1, 1, -1);
is $f->point(1, 1), $max, 'update wraps from minimum to maximum';
is $f->set(1, 1, $min), $max, 'set returns maximum across overflowing delta';
is $f->point(1, 1), $min, 'set stores minimum across overflowing delta';
is $f->set(1, 1, $max), $min, 'set returns minimum across overflowing delta';
is $f->point(1, 1), $max, 'set stores maximum across overflowing delta';

$f->clear;
$f->set(2, 2, $max);
$f->set(3, 3, 1);
is $f->prefix(3, 3), $min, 'prefix accumulation wraps across nodes';
is $f->total, $min, 'total uses the same wraparound';
is $f->stats->{total}, $min, 'stats uses the same wraparound';
is $f->rect(2, 2, 3, 3), $min, 'rectangle sum wraps';
is $f->point(3, 3), 1, 'inclusion-exclusion recovers a cell from wrapped sums';

$f->clear;
$f->set(1, 1, $min);
$f->set(2, 2, -1);
is $f->prefix(2, 2), $max, 'negative sum wraps';
is $f->rect(2, 2, 2, 2), -1, 'rectangle subtraction wraps';
is $f->point(1, 1), $min, 'minimum value survives cancellation';

done_testing;
