# $Id: Makefile.PL 13 1998-12-16 23:05:28Z daniel $

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Apache::AuthenRadius',
	'VERSION_FROM'	=> 'AuthenRadius.pm', 
	'PREREQ_PM'	=> { 'Authen::Radius' => 0.06 },
	'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
