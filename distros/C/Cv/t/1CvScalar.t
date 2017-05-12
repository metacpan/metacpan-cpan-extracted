# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	plan skip_all => "no Cv/t.so" if $@;
	plan tests => 17;
}
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my @val = unpack("d*", pack("d*", map { rand 1 } 0..3));
my $scalar = Cv::cvScalar(@val);
is_deeply($scalar, \@val);

{
	my $sc = Cv::cvScalar($val[0]);
	is_deeply($sc, [ $val[0], 0, 0, 0 ]);
}

{
	my $sc = Cv::cvScalar(@val[0 .. 1]);
	is_deeply($sc, [ @val[0 .. 1], 0, 0 ]);
}

{
	my $sc = Cv::cvScalar(@val[0 .. 2]);
	is_deeply($sc, [ @val[0 .. 2], 0 ]);
}

TODO: {
	local $TODO = "usage";

	throws_ok { Cv::cvScalar() } qr/Usage: Cv::cvScalar\(val0, val1=0, val2=0, val3=0\) at $0/;

	throws_ok { Cv::cvScalar(1, 2, 3, 4, 5) } qr/Usage: Cv::cvScalar\(val0, val1=0, val2=0, val3=0\) at $0/;
}

if (1) {
	{
		my $sc = Cv::CvScalar($scalar);
		is_deeply($sc, $scalar);
	}

	{
		throws_ok { Cv::CvScalar() } qr/Usage: Cv::CvScalar\(scalar\) at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvScalar(['1x', $val[1], $val[2], $val[3]]) };
		is_deeply($x, [ 1, @val[1..3] ]);
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvScalar([$val[0], '2x', $val[2], $val[3]]) };
		is_deeply($x, [ $val[0], 2, @val[2..3] ]);
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvScalar([$val[0], $val[1], '3x', $val[3]]) };
		is_deeply($x, [ @val[0..1], 3, $val[3] ]);
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvScalar([$val[0], $val[1], $val[2], '4x']) };
		is_deeply($x, [ @val[0..2], 4 ]);
	}
}
