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

my ($x, $y) = map { int rand 65536 } 0..1;
my $pt = cvPoint($x, $y);
is_deeply($pt, [ $x, $y ]);

if (1) {
	{
		my $pt2 = Cv::CvPoint($pt);
		is_deeply($pt2, $pt);
	}

	throws_ok { Cv::CvPoint([]) } qr/pt is not of type CvPoint in Cv::CvPoint at $0/;

	throws_ok { Cv::CvPoint([1]) } qr/pt is not of type CvPoint in Cv::CvPoint at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvPoint(['1x', '2y']) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvPoint(['1x', '2y']) };
		is_deeply($x, [ 1, 2 ]);
	}

	eval "use Time::Piece";
	if ($@) {
		ok(1);
	} else {
		my $t1 = Time::Piece->strptime("2012-01-01", "%Y-%m-%d");
		my $t2 = Time::Piece->strptime("2012-01-02", "%Y-%m-%d");
		my $pt2 = Cv::CvPoint([$t2 - $t1, 0]);
		is_deeply($pt2, [ $t2 - $t1, 0 ]);
	}
}
