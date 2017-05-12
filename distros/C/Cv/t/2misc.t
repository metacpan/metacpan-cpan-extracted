# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 42;
use Test::Number::Delta within => 1e-7;
use Test::Exception;
use POSIX;
BEGIN { use_ok('Cv', -nomore) }

sub cbrt {
    my ($x) = @_; my $sign = 1;
    ($x, $sign) = (-$x, -1) if $x < 0;
    $sign * $x ** (1/3);
}

for my $x (-1.5, -1, -0.5, 0, 0.5, 1, 1.5) {
    delta_ok(cvCbrt($x), cbrt($x), "cvCbrt($x)");
}

for my $x (-1.5, -1, -0.5, 0, 0.5, 1, 1.5) {
	if ($x >= 0) {
		delta_ok(cvSqrt($x), sqrt($x), "cvSqrt($x)");
	} else {
		like(cvSqrt($x), qr/-?nan/i, "cvSqrt($x)");
	}
}

for my $x (-1, -0.5, 0, 0.5, 1) {
    is(cvFloor($x), POSIX::floor($x) + 0, "cvFloor($x)");
}

for my $x (-1, -0.5, 0, 0.5, 1) {
    is(cvCeil($x), POSIX::ceil($x) + 0, "cvCeil($x)");
}

for (1 .. 10) {
    my ($y, $x) = (rand(), rand());
    delta_within(cvFastArctan($y, $x), 180/CV_PI*atan2($y, $x),
				 0.5, "cvFastArctan($y, $x)");
}

for my $x (-1.4, -1, -0.6, 0, 0.6, 1, 1.4) {
	if ($x >= 0) {
		is(cvRound($x), POSIX::floor($x + 0.5), "round($x)");
	} else {
		is(cvRound($x), POSIX::ceil($x - 0.5), "round($x)");
	}
}
