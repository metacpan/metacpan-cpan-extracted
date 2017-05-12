# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 73;
use Test::Exception;
BEGIN { use_ok('Cv') }

if (1) {
	my $stor = Cv::MemStorage->new(8192);
	ok($stor->isa('Cv::MemStorage'));

	my $seq = Cv::Seq::Point->new(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	my @pts = (map { [ $_ * 10 + 1, $_ * 10 + 2 ] } 0 .. 9);
	$seq->Push(@pts);
	is_deeply([$seq->GetSeqElem($_)], $pts[$_]) for 0 .. $#pts;

	$seq->SeqInvert;
	@pts = reverse(@pts);
	is_deeply([$seq->GetSeqElem($_)], $pts[$_]) for 0 .. $#pts;

	$seq->Reverse;
	@pts = reverse(@pts);
	is_deeply([$seq->GetSeqElem($_)], $pts[$_]) for 0 .. $#pts;
}

if (2) {
	my $stor = Cv::MemStorage->new(8192);
	ok($stor->isa('Cv::MemStorage'));

	my $seq = Cv::Seq::Point->new(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	my @pts = (map { [ $_ * 10 + 1, $_ * 10 + 2 ] } 0 .. 9);
	$seq->Push(@pts);

	my @arr = $seq->CvtSeqToArray;
	is_deeply([@arr], [@pts]);

	$seq->cvtSeqToArray(\@arr);
	is_deeply([@arr], [@pts]);
	is_deeply([@$seq], [@pts], 'overload');

	my $slice2 = [ 2, 5 ];
	my @arr2 = $seq->ToArray([], $slice2);
	my @pts2 = @pts[$slice2->[0] .. $slice2->[1] - 1];
	is_deeply([@arr2], [@pts2]);

	$seq->ToArray(\@arr2, $slice2);
	is_deeply([@arr2], [@pts2]);

	my $arr2 = $seq->toArray([], $slice2);
	is_deeply([@$arr2], [@pts2]);

	my $slice3 = [ 3, 7 ];
	my @arr3 = $seq->toArray($slice3);
	my @pts3 = @pts[$slice3->[0] .. $slice3->[1] - 1];
	is_deeply([@arr3], [@pts3]);

	my $arr3 = $seq->toArray($slice3);
	is_deeply([@$arr3], [@pts3]);
}


if (3) {
	my $stor = Cv::MemStorage->new;
	ok($stor->isa('Cv::MemStorage'));
	my $seq = Cv::Seq::Point->new(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	$seq->Push([0, 1], [2, 3]);
	is($seq->total, 2);

	my $p = $seq->Shift;
	is_deeply([@$p], [0, 1]);

	my $q = $seq->Shift;
	is_deeply([@$q], [2, 3]);
}


if (4) {
	my $stor = new Cv::MemStorage;
	ok($stor->isa('Cv::MemStorage'));
	my $seq = new Cv::Seq::Point(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	$seq->Unshift([0, 1], [2, 3]);
	is($seq->total, 2);

	my $p = $seq->Pop;
	is_deeply([@$p], [0, 1]);

	my $q = $seq->Pop;
	is_deeply([@$q], [2, 3]);
}


if (5) {
	my $stor = Cv::MemStorage->new;
	ok($stor->isa('Cv::MemStorage'));
	my $seq = Cv::Seq::Point->new(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	$seq->Push([1, 1], [2, 2]);
	is($seq->total, 2);

	my @arr = $seq->Splice(1, 1);
	is($seq->total, 1);
	is_deeply($arr[0], [2, 2]);

	$seq->Push([2, 2], [3, 3]);
	is($seq->total, 3);

	$seq->Splice(1);
	is($seq->total, 1);

	$seq->Splice(0);
	is($seq->total, 0);

	$seq->Push([1, 1], [2, 2], [3, 3]);
	is($seq->total, 3);

	$seq->Splice(1, 1, [4, 4], [5, 5]);
	is($seq->total, 4);
}

if (6) {
	my $stor = Cv::MemStorage->new;
	ok($stor->isa('Cv::MemStorage'));
	my $seq = Cv::Seq::Point->new(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	$seq->Push([1, 1], [2, 2]);
	is($seq->total, 2);
	my $p0 = $seq->Get(0);
	is($p0->[0], 1);

	$seq->Set(0, [3, 3]);
	my $p1 = $seq->Get(0);
	is($p1->[0], 3);
}


# new() with init
if (7) {
	my $stor = Cv::MemStorage->new;
	ok($stor->isa('Cv::MemStorage'));
	my @pts = ([1, 2], [3, 4], [5, 6]);
	my $seq = Cv::Seq::Point->new(CV_32FC2, $stor, @pts);
	ok($seq);
	is($seq->total, scalar @pts);
	my @list = $seq->toArray;
	is(scalar @list, 3);
	is_deeply([@list], [@pts]);
}
