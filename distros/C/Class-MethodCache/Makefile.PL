#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile(
	NAME         => 'Class::MethodCache',
	VERSION_FROM => 'lib/Class/MethodCache.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Sub::Exporter' => 0,
		'Test::Exception' => 0,
	},
);

