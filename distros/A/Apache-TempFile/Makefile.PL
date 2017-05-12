# $Id: Makefile.PL,v 1.1 1998/08/12 22:16:42 tom Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Apache::TempFile',
	VERSION_FROM => 'TempFile.pm',
	PREREQ_PM    => { Apache => 0 },
);
