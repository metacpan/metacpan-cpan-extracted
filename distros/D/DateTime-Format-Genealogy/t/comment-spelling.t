#!usr/bin/env perl

use 5.006;
use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING} ) {
	# Don't use 'eval { use ... ' as recommended by Perlcritic
	# See https://www.cpantesters.org/cpan/report/6db47260-389e-11ec-bc66-57723b537541
	eval 'use Test::Spelling::Comment 0.002';
	if($@) {
		plan(skip_all => 'Test::Spelling::Comment required for testing comment spelling');
	} else {
		Test::Spelling::Comment->new()->add_stopwords(<DATA>)->all_files_ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}

__DATA__
Gedcom
