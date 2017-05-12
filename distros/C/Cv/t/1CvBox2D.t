# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	plan skip_all => "no Cv/t.so" if $@;
	plan tests => 9;
}
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $center = [ unpack("f*", pack("f*", map { rand 1 } 0..1)) ];
my $size = [ unpack("f*", pack("f*", map { rand 1 } 0..1)) ];
my $angle = unpack("f", pack("f", map { rand 1 } 0));

if (1) {
	{
		my $b = Cv::cvBox2D($center, $size, $angle);
		is_deeply($b, [$center, $size, $angle]);
		my $b2 = Cv::CvBox2D($b);
		is_deeply($b2, $b);
	}

	throws_ok { Cv::CvBox2D([]) } qr/box is not of type CvBox2D in Cv::CvBox2D at $0/;

	throws_ok { Cv::CvBox2D(['x', $size, $angle]) } qr/box is not of type CvBox2D in Cv::CvBox2D at $0/;

	throws_ok { Cv::CvBox2D([$center, 'x', $angle]) } qr/box is not of type CvBox2D in Cv::CvBox2D at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvBox2D([$center, $size, '1.5x']) } qr/Argument \"1\.5x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvBox2D([$center, $size, '1.5x']) };
		is_deeply($x, [$center, $size, 1.5]);
	}
}
