# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 8;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $release_ok = 0;
	no warnings 'redefine';
	local *Cv::MemStorage::DESTROY = sub {
		&Cv::MemStorage::cvReleaseMemStorage;
		$release_ok++;
	};
	if (1.1) {
		is($Cv::STORAGE, undef);
	}
	if (1.2) {
		local $Cv::STORAGE = $Cv::STORAGE;
		my $mem = &Cv::STORAGE;
		isa_ok($Cv::STORAGE, 'Cv::MemStorage');
	}
	if (1.9) {
		ok($release_ok);
		is($Cv::STORAGE, undef);
	}
}

if (2) {
	if (2.1) {
		is($Cv::STORAGE, undef);
	}
	if (2.2) {
		local $Cv::STORAGE = $Cv::STORAGE;
		my $seq = Cv::Seq::Point->new();
		isa_ok($seq, 'Cv::Seq::Point');
	}
	if (2.9) {
		is($Cv::STORAGE, undef);
	}
}
