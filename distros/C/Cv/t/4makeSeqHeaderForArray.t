# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 28;
use Test::Exception;
BEGIN { use_ok('Cv') }

my $verbose = 0;

if (1) {
	my $stor = Cv::MemStorage->new(8192);
	ok($stor->isa('Cv::MemStorage'));

	my $seq = Cv::Seq::Point->new(CV_32SC2, $stor);
	ok($seq->isa('Cv::Seq::Point'));

	my @pts = (map { [ $_ * 10 + 1, $_ * 10 + 2 ] } 0 .. 9);
	$seq->Push(@pts);
	is_deeply([$seq->GetSeqElem($_)], $pts[$_]) for 0 .. $#pts;

	Cv::Seq::CvtSeqToArray($seq, my $elements);

	if ($verbose) {
		print STDERR "\n";
		print STDERR '$seq->flags       = ', $seq->flags, "\n";
		print STDERR '$seq->header_size = ', $seq->header_size, "\n";
		print STDERR '$seq->elem_size   = ', $seq->elem_size, "\n";
		print STDERR '$seq->total       = ', $seq->total, "\n";
		print STDERR 'length($elements) = ', length($elements), "\n";
	}

	my $seq2 = Cv::Seq::Point->MakeSeqHeaderForArray(
		undef,					# or CV_32SC2
		0,						# or &Cv::Sizeof::CvSeq, $seq->header_size
		0,						# or 8, $seq->elem_size
		$elements,
		my $tmpseq,
		my $tmpblock,
		);

	if (1) {
		my $cn = 2;
		my $type = CV_MAKETYPE(CV_32S, $cn);
		my $seq = $seq2; # Cv::Seq::Point->new($type, $stor);
		isa_ok($seq, 'Cv::Seq::Point');
		is(&CV_MAT_TYPE($seq->flags), $type, 'MAT_TYPE(flags)');
		is(&CV_MAT_DEPTH($seq->flags), CV_32S, 'MAT_DEPTH(flags)');
		is(&CV_MAT_CN($seq->flags), $cn, 'MAT_CN(flags)');
		my $elem_type = &CV_MAT_TYPE($seq->flags);
		is(&CV_ELEM_SIZE($elem_type), 4 * $cn, 'ELEM_SIZE(type)');
	}

	if ($verbose) {
		print STDERR 'length($tmpseq)   = ', length($tmpseq), "\n";
		print STDERR 'length($tmpblock) = ', length($tmpblock), "\n";
	}

	is_deeply([$seq2->GetSeqElem($_)], $pts[$_]) for 0 .. $#pts;

	if ($verbose) {
		use Time::HiRes qw(gettimeofday);
		my $t0 = gettimeofday();
		for (0 .. 1000) {
			my @arr =  map { $seq2->GetSeqElem($_) } 0 .. $#pts;
		}
		my $t1 = gettimeofday();
		printf STDERR ("GetSeqElem: %.3f(ms/seq)\n",
					   ($t1 - $t0)/scalar @pts);
	}
}
