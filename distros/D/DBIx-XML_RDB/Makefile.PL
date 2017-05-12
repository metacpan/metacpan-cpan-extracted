#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::XML_RDB',
    'VERSION_FROM' => 'XML_RDB.pm', # finds $VERSION
	'EXE_FILES' => ['sql2xml.pl', 'xml2sql.pl'],
	'PREREQ_PM' => { DBI => "1.00" },
	'dist' => {'COMPRESS' => 'gzip', suffix => 'gz' },
);
