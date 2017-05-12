use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.2 2004/03/27 13:43:12 cwg Exp $

WriteMakefile(
    'NAME'	        => 'DBIx::LazyMethod',
    'VERSION_FROM'  => 'lib/DBIx/LazyMethod.pm', # finds $VERSION
	'PREREQ_PM' => {
		'POSIX'         => 0,
		'Test::Harness' => 0,
		'Test::More'    => 0,
		'DBI'    	=> 0,
	}
);
