#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'BSD::Ipfwgen',
	'DISTNAME' => 'BSD-Ipfwgen',
	'VERSION' => '1.5',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
