# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	plan skip_all => "no Cv/t.so" if $@;
	plan tests => 16;
}
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $area = int rand 16384;
my $value = [ map { (int rand 16384) + 0.5 } 0..3 ];
my $rect = [ map { int rand 16384 } 0..3 ];
my $contour = Cv::Seq->new(CV_8UC4);

if (1) {
	{
		my $cc = Cv::cvConnectedComp($area, $value, $rect, $contour);
		is($cc->[0], $area);
		is_deeply($cc->[1], $value);
		is_deeply($cc->[2], $rect);
		# is($cc->[3], $contour);

		my $cc2 = Cv::CvConnectedComp($cc);
		is($cc2->[0], $cc->[0]);
		is_deeply($cc2->[1], $cc->[1]);
		is_deeply($cc2->[2], $cc->[2]);
		# is($out->[3], $cc->[3]);
	}

	throws_ok { Cv::CvConnectedComp([]) } qr/cc is not of type CvConnectedComp in Cv::CvConnectedComp at $0/;

	throws_ok { Cv::CvConnectedComp([$area, 'x', $rect, $contour]) } qr/cc is not of type CvConnectedComp in Cv::CvConnectedComp at $0/;

	throws_ok { Cv::CvConnectedComp([$area, $value, 'x', $contour]) } qr/cc is not of type CvConnectedComp in Cv::CvConnectedComp at $0/;

	throws_ok { Cv::CvConnectedComp([$area, $value, $rect, 'x']) } qr/cc is not of type CvConnectedComp in Cv::CvConnectedComp at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::CvConnectedComp(['1x', $value, $rect, $contour]) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::CvConnectedComp(['1x', $value, $rect, $contour]) };
		is($x->[0], 1);
		is_deeply($x->[1], $value);
		is_deeply($x->[2], $rect);
		# is($x->[3], $contour);
	}
}
