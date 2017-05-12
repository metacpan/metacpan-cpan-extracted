#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'B::XSUB::Dumber',
	VERSION_FROM => 'lib/B/XSUB/Dumber.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Test::Benchmark' => 0,
		'B::OPCheck' => 0.27,
	},
);

