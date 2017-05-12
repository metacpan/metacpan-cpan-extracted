# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	plan skip_all => "no Cv/t.so" if $@;
	plan tests => 10;
}
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my ($x, $y) = map { (int rand 65536) } 0..1;

if (1) {
	my $arr = Cv::cvPointPtr($x, $y);
	is(ref $arr, 'ARRAY');
	is(scalar @$arr, 1);
	is_deeply($arr, [ [ $x, $y ] ]);

	{
		my $arr2 = Cv::CvPointPtr($arr->[0]);
		is_deeply($arr2, $arr);
	}

	throws_ok { Cv::CvPointPtr([]) } qr/pt is not of type CvPoint in Cv::CvPointPtr at $0/;

	throws_ok { Cv::CvPointPtr([1]) } qr/pt is not of type CvPoint in Cv::CvPointPtr at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvPointPtr(['1x', '2y']) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvPointPtr(['1x', '2y']) };
		is_deeply($x, [ [1, 2] ]);
	}
}
