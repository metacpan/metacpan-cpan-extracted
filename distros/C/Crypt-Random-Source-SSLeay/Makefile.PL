#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Crypt::Random::Source::SSLeay',
	VERSION_FROM => 'lib/Crypt/Random/Source/SSLeay.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Net::SSLeay' => 0,
		'Crypt::Random::Source' => 0.05,
		'Moose' => 0.92,
	},
);

