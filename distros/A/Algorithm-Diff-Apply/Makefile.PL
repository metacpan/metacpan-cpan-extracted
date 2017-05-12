#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile( NAME => "Algorithm::Diff::Apply",
	       VERSION_FROM => 'lib/Algorithm/Diff/Apply.pm',
	       PREREQ_PM => {
		       'Algorithm::Diff' => 0,
	       } );
