# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 172;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $b = Cv::Image->new([3, 3], CV_8UC1);
	isa_ok($b, 'Cv::Image');
	$b->fill([1]);
	my $g = $b->new;
	isa_ok($g, 'Cv::Image');
	$g->fill([2]);
	my $r = $b->new;
	isa_ok($r, 'Cv::Image');
	$r->fill([3]);
	foreach my $row (0 .. $b->rows - 1) {
		foreach my $col (0 .. $b->cols - 1) {
			is(${$b->Get([$row, $col])}[0], 1);
			is(${$g->Get([$row, $col])}[0], 2);
			is(${$r->Get([$row, $col])}[0], 3);
		}
	}

	my $bgr = Cv->Merge($b, $g, $r);
	isa_ok($bgr, ref $b);
	is($bgr->type, CV_8UC3);
	foreach my $row (0 .. $bgr->rows - 1) {
		foreach my $col (0 .. $bgr->cols - 1) {
			my $x = $bgr->Get([$row, $col]);
			is($x->[0], 1);
			is($x->[1], 2);
			is($x->[2], 3);
		}
	}

	my $bgr2 = Cv->Merge([$b, $g, $r]);
	foreach my $row (0 .. $bgr2->rows - 1) {
		foreach my $col (0 .. $bgr2->cols - 1) {
			my $x = $bgr2->Get([$row, $col]);
			is($x->[0], 1);
			is($x->[1], 2);
			is($x->[2], 3);
		}
	}

	Cv->Merge([$b, $g, $r], my $bgr3 = Cv::Image->new($b->sizes, CV_8UC3));
	foreach my $row (0 .. $bgr3->rows - 1) {
		foreach my $col (0 .. $bgr3->cols - 1) {
			my $x = $bgr3->Get([$row, $col]);
			is($x->[0], 1);
			is($x->[1], 2);
			is($x->[2], 3);
		}
	}

	Cv->Merge($b, $g, $r, \0, my $bgr4 = Cv::Image->new($b->sizes, CV_8UC3));
	foreach my $row (0 .. $bgr4->rows - 1) {
		foreach my $col (0 .. $bgr4->cols - 1) {
			my $x = $bgr4->Get([$row, $col]);
			is($x->[0], 1);
			is($x->[1], 2);
			is($x->[2], 3);
		}
	}

	Cv->Merge($b, $g, $r, my $bgr5 = Cv::Image->new($b->sizes, CV_8UC3));
	foreach my $row (0 .. $bgr5->rows - 1) {
		foreach my $col (0 .. $bgr5->cols - 1) {
			my $x = $bgr5->Get([$row, $col]);
			is($x->[0], 1);
			is($x->[1], 2);
			is($x->[2], 3);
		}
	}
}

if (10) {
	throws_ok { Cv->Merge; } qr/Usage: Cv::Arr::Merge\(\[src0, src1, \.\.\.\], dst\) at $0/;
	my $cv = bless [], 'Cv';
	throws_ok { $cv->Merge; } qr/Usage: Cv::Arr::Merge\(\[src0, src1, \.\.\.\], dst\) at $0/;
}

if (11) {
	my $x = Cv::Mat->new([320, 240], CV_8UC1);
	my ($b, $g, $r, $a) = ($x->new, $x->new, $x->new, $x->new);
	throws_ok { Cv->Merge($b, $g, $r, $a, $x->new) } qr/OpenCV Error:/;
	throws_ok { Cv->Merge([$b, $g, $r, $a], $x->new) } qr/OpenCV Error:/;
}
