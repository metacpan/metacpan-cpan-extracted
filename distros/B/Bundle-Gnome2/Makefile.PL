# $Id: Makefile.PL,v 1.1.1.1 2003/10/17 14:57:21 jodrell Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Bundle::Gnome2',
	VERSION_FROM	=> 'Gnome2.pm',
	'dist'		=> {
		COMPRESS => 'gzip -9f',
		SUFFIX   => '.gz',
		DIST_DEFAULT => 'all tardist',
	},
);
