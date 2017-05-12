# $Id: Makefile.PL,v 1.2 2007/04/12 11:24:29 dk Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Array::Slice',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'Slice.pm',
	VERSION_FROM  => 'Slice.pm',
	OBJECT        => 'Slice.o',
	PREREQ_PM     => { Want => 0 },
);
