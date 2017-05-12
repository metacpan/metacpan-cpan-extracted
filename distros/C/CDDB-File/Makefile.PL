use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'CDDB::File',
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	VERSION_FROM  => 'lib/CDDB/File.pm',
	ABSTRACT_FROM => 'lib/CDDB/File.pm',
	PREREQ_PM     => { 'Test::More' => 0.17, },
);
