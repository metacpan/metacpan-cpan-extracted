#!/usr/bin/perl
use strict;
use warnings;
use constant EPSILON => 0.1;

use Test::More tests => 7;
BEGIN { use_ok('Audio::LibSampleRate') };

sub isf {
	my ($xx, $yy, $name) = @_;
	for (0 .. $#{$xx}) {
		my ($x, $y) = ($xx->[$_], $yy->[$_]);
		do { diag "$x != $y"; return fail $name } if abs ($x - $y) > EPSILON;
	}
	pass $name;
}

isf [src_simple([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6], 2)], [1.1, 1.1, 1.7, 1.7, 1.9, 1.9, 2.2, 2.2, 3.1, 3.1, 3.8, 3.8], 'src_simple doubling';
isf [src_simple([1..10], 1/2, SRC_LINEAR, 1)], [1, 2, 4, 6, 8], 'src_simple halving';

my @out;
my $src = Audio::LibSampleRate->new(SRC_ZERO_ORDER_HOLD, 1);
@out = ($src->process([1.. 5], 1/2), $src->process([6..10], 2, 1));
isf \@out, [1, 2, 4, 6, 8, 9], 'process, smooth transition';

$src->reset;
@out = $src->process([1..5], 1/2);
$src->set_ratio(2);
push @out, $src->process([6..10], 2, 1);
isf \@out, [1, 2, 4, 6, 6, 7, 7, 8, 8, 9, 9, 10], 'process, step transition';

is src_get_name(SRC_SINC_FASTEST), 'Fastest Sinc Interpolator', 'src_get_name';
like src_get_description(SRC_SINC_FASTEST), qr/band limited sinc interpolation/i, 'src_get_description';
