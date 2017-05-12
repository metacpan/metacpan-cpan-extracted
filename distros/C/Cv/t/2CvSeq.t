# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 63;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $stor = Cv::MemStorage->new;

if (1) {
	no warnings;
	my $destroy = 0;
	local *{Cv::Seq::DESTROY} = sub { $destroy++; };
	foreach my $cn (1 .. 4) {
		my $type = CV_MAKETYPE(CV_32S, $cn);
		my $seq = Cv::Seq->new($type, $stor);
		isa_ok($seq, 'Cv::Seq');
		is(&CV_MAT_TYPE($seq->flags), $type, 'MAT_TYPE(flags)');
		is(&CV_MAT_DEPTH($seq->flags), CV_32S, 'MAT_DEPTH(flags)');
		is(&CV_MAT_CN($seq->flags), $cn, 'MAT_CN(flags)');
		my $elem_type = &CV_MAT_TYPE($seq->flags);
		is(&CV_ELEM_SIZE($elem_type), 4 * $cn, 'ELEM_SIZE(type)');
	}
	is($destroy, 4);

	my $Cv = bless [], 'Cv';
	throws_ok { $Cv->CreateSeq() } qr/class name needed at $0/;

	my $Cv_Seq = bless [], 'Cv::Seq';
	throws_ok { $Cv_Seq->CreateSeq() } qr/class name needed at $0/;
}

if (2) {
	my $cn = 3;
	foreach (
		[ CV_8S,  1 ], [ CV_8U,  1 ],
		[ CV_16S, 2 ], [ CV_16U, 2 ],
		[ CV_32S, 4 ], [ CV_64F, 8 ],
		) {
		my ($ty, $sz) = @$_;
		my $type = CV_MAKETYPE($ty, $cn);
		# my $seq = Cv::Seq::Point->new($type, $stor);
		my $seq = Cv::Seq->new($type, $stor);
		isa_ok($seq, 'Cv::Seq');
		is(&CV_MAT_TYPE($seq->flags), $type, 'MAT_TYPE(flags)');
		is(&CV_MAT_DEPTH($seq->flags), $ty, 'MAT_DEPTH(flags)');
		is(&CV_MAT_CN($seq->flags), $cn, 'MAT_CN(flags)');
		my $elem_type = &CV_MAT_TYPE($seq->flags);
		is(&CV_ELEM_SIZE($elem_type), $sz * $cn, 'ELEM_SIZE(type)');
	}
}

if (3) {
	my $seq = Cv::Seq->new;
	$seq->push(pack("i2", 100, 200));
	my @pt = unpack("i2", $seq->pop);
	is_deeply([@pt], [100, 200]);
	$seq->push(pack("i2", 101, 201));
	my @pt2 = unpack("i2", $seq->get(0));
	is_deeply([@pt2], [101, 201]);
	$seq->set(0, pack("i2", 111, 222));
	my @pt3 = unpack("i2", $seq->shift);
	is_deeply([@pt3], [111, 222]);
	$seq->unshift(pack("i2", @pt3));
	my @pt4 = unpack("i2", $seq->shift);
	is_deeply([@pt4], [111, 222]);
}

if (4) {
	my $src = Cv::Seq->new;
	my $seq = $src->new;
	is($seq->type, $src->type);

	for my $dst_class (qw(Cv::Mat Cv::MatND Cv::SparseMat Cv::Image)) {
		my $new = "${dst_class}::new";
		my $mat = $src->$new([240, 320]);
		is($mat->type, $src->type);
	}
}
