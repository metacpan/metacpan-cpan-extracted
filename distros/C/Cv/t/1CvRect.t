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

my ($x, $y, $width, $height) = map { int rand 16384 } 0..3;
my $rect = Cv::cvRect($x, $y, $width, $height);
is_deeply($rect, [$x, $y, $width, $height]);

if (1) {
	{
		my $rect2 = Cv::CvRect($rect);
		is_deeply($rect2, $rect);
	}

	throws_ok { Cv::CvRect([]) } qr/rect is not of type CvRect in Cv::CvRect at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvRect(['1x', $y, $width, $height]) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
		throws_ok { Cv::CvRect([$x, '2x', $width, $height]) } qr/Argument \"2x\" isn't numeric in subroutine entry at $0/;
		throws_ok { Cv::CvRect([$x, $y, '3x', $height]) } qr/Argument \"3x\" isn't numeric in subroutine entry at $0/;
		throws_ok { Cv::CvRect([$x, $y, $width, '4x']) } qr/Argument \"4x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvRect(['1x', '2x', '3x', '4x']) };
		is_deeply($x, [ 1, 2, 3, 4 ]);
	}
}

