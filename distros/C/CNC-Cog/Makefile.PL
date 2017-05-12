#!/usr/bin/perl

	use 5.008;
	use ExtUtils::MakeMaker;
	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.
	WriteMakefile(
	    NAME              => 'CNC::Cog',
	    VERSION_FROM      => 'Cog.pm', # finds $VERSION
	    PREREQ_PM         => {GD => 2.11 }, # e.g., Module::Name => 1.1
	    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	      (
           ABSTRACT  => 'A module for cutting cog wheels from sheet metal using a CNC milling machine. ', # retrieve abstract from module
#            ABSTRACT_FROM => 'Cog.pm',
	       AUTHOR         => 'Mark Winder <mark.winder4@btinternet.com>') : ()),
	);

