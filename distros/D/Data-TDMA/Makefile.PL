#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Data::TDMA',
	VERSION      => '0.2',
	dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	AUTHOR       => 'Jane A. Avriette <jane@cpan.org>',
	ABSTRACT     => 'Time Division Multiple Access abstraction for perl. Deprecates Net::TDMA',
);
