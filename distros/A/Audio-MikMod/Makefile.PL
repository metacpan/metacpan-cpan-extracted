# $Id: Makefile.PL,v 1.2 1999/07/28 02:01:21 daniel Exp $

use ExtUtils::MakeMaker;

sub MY::libscan {
	my ($self,$path) = @_;
	return '' if (
		$path =~ m:/(RCS|CVS|SCCS)/: ||
		$path =~ m:[~%]$: ||
		$path =~ m:\.(orig|rej)$:
	);
	return $path;
}

WriteMakefile(
	'NAME'		=> 'Audio::MikMod',
	'dist'		=> { COMPRESS => 'gzip', SUFFIX => '.gz'},
	'VERSION_FROM'	=> 'MikMod.pm',
	'LIBS'		=> ['-lmikmod'],
	'DEFINE'	=> '',
	'INC'		=> '',
	'PREREQ_PM'	=> {'Time::HiRes' => 1.20},
);
