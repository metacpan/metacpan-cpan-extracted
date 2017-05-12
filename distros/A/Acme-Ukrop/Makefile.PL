# $Id: Makefile.PL,v 1.2 2008/04/10 21:56:39 dk Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Acme::Ukrop',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'Ukrop.pm',
	VERSION_FROM  => 'Ukrop.pm',
	PREREQ_PM     => { 'Filter::Simple' => 0, },
);
