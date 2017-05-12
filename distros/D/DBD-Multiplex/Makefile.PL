use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence the contents of the Makefile that is written.

WriteMakefile (
		'NAME'			=> 'DBD::Multiplex',
		'VERSION_FROM'		=> 'lib/DBD/Multiplex.pm',
		'AUTHOR'		=> 'Thomas Kishel <tkishel+perl@gmail.com>',
		'PREREQ_PM'		=> { DBI::DBD => 1 },
);
