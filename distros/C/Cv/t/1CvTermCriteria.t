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

my ($type, $max_iter) = map { int rand 65536 } 1 .. 2;
my ($epsilon) = map { int rand 10 } 3;
my $term = cvTermCriteria($type, $max_iter, $epsilon);
is_deeply($term, [$type, $max_iter, $epsilon]);

if (1) {
	{
		my $term2 = Cv::CvTermCriteria($term);
		is_deeply($term2, $term);
	}

	throws_ok { Cv::CvTermCriteria({}) } qr/term is not of type CvTermCriteria in Cv::CvTermCriteria at $0/;

	throws_ok { Cv::CvTermCriteria([]) } qr/term is not of type CvTermCriteria in Cv::CvTermCriteria at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvTermCriteria(['1x', 2, 3]) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
		throws_ok { Cv::CvTermCriteria([1, '2x', 3]) } qr/Argument \"2x\" isn't numeric in subroutine entry at $0/;
		throws_ok { Cv::CvTermCriteria([1, 2, '3x']) } qr/Argument \"3x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvTermCriteria(['1x', '2x', '3x']) };
		is_deeply($x, [ 1, 2, 3 ]);
	}
}
