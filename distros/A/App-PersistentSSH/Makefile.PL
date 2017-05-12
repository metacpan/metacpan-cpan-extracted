#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'App::PersistentSSH',
	VERSION_FROM => 'lib/App/PersistentSSH.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	EXE_FILES    => [qw(bin/persisshtent)],
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'MooseX::POE' => 0,
		'MooseX::Getopt' => '0.15',
		'MooseX::LogDispatch' => 0,
		'namespace::clean' => 0,
	},
);

