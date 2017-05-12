#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Crypt::IDEA',
	'DISTNAME' => 'Crypt-IDEA',
	'VERSION_FROM' => 'IDEA.pm',
	'OBJECT' => 'IDEA.o _idea.o',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

