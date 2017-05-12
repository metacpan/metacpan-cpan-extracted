#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
	NAME         => 'Crypt::EAX',
	VERSION_FROM => 'lib/Crypt/EAX.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Test::Exception' => 0,
		'Digest::CMAC' => '0.04', # prev versions have a bug
		'Crypt::Ctr' => 0,
		'Moose' => '0.92',
		'namespace::clean' => '0.08',
	},
);

