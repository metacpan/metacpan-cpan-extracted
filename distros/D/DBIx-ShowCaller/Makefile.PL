
use 5.004;

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'DBIx::ShowCaller',
	'VERSION_FROM'	=> 'ShowCaller.pm',
	'PREREQ_PM'	=> { 'DBI' => 1.13 },
        'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	);

