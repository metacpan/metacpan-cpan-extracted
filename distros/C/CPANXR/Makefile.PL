# $Id: Makefile.PL,v 1.5 2003/10/06 21:41:28 clajac Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(NAME	   => 'CPANXR',
	      VERSION_FROM => 'CPANXR.pm', # finds $VERSION
	      PREREQ_PM	   => {
			       Config::Simple   => 4.55,
			       DBI              => 1.37,
			       DBD::mysql       => 2.9002,
			       File::Find::Rule => 0.11,
			       PPI              => 0.805,
			       GraphViz         => 1.8,
			       Data::Page       => 0.18,
			      },
	      EXE_FILES    => [qw(bin/cpanxr)],
	      AUTHOR       => 'Claes Jacobsson <claes@surfar.nu>',
	     );
