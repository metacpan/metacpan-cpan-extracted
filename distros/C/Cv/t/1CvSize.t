# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	plan skip_all => "no Cv/t.so" if $@;
	plan tests => 8;
}
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my ($width, $height) = map { int rand 16384 } 0..1;
my $size = Cv::cvSize($width, $height);
is_deeply($size, [$width, $height]);

if (1) {
	{
		my $size2 = Cv::CvSize($size);
		is_deeply($size2, $size);
	}

	throws_ok { Cv::CvSize([]) } qr/size is not of type CvSize in Cv::CvSize at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvSize(['1x', $height]) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
		throws_ok { Cv::CvSize([$width, '2x']) } qr/Argument \"2x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvSize(['1x', '2x']) };
		is_deeply($x, [ 1, 2 ]);
	}
}
