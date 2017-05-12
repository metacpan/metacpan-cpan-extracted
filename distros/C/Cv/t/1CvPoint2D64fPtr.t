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

my ($x, $y) = unpack("f*", pack("f*", map { rand 1 } 0..1));

if (1) {
	my $arr = Cv::cvPoint2D64fPtr($x, $y);
	is(ref $arr, 'ARRAY');
	is(scalar @$arr, 1);
	is_deeply($arr, [ [ $x, $y ] ]);

	{
		my $arr2 = Cv::CvPoint2D64fPtr($arr->[0]);
		is_deeply($arr2, $arr);
	}

	throws_ok { Cv::CvPoint2D64fPtr([]) } qr/pt is not of type CvPoint2D64f in Cv::CvPoint2D64fPtr at $0/;

	throws_ok { Cv::CvPoint2D64fPtr([1]) } qr/pt is not of type CvPoint2D64f in Cv::CvPoint2D64fPtr at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvPoint2D64fPtr(['1x', '2y']) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvPoint2D64fPtr(['1x', '2y']) };
		is_deeply($x, [ [1, 2] ]);
	}
}
