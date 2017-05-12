#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Crypt::Random::Source::Weak::OpenSSLRand',
	VERSION_FROM => 'lib/Crypt/Random/Source/Weak/OpenSSLRand.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'OpenSSL::Rand' => 0,
		'Crypt::Random::Source' => '0.02',
		'Mouse' => '0.04',
	},
);

