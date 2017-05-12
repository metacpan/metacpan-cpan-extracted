use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Convert SQL into a JavaScript database',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST DBIx-HTML-ClientDB-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'DBIx-HTML-ClientDB',
	NAME			=> 'DBIx::HTML::ClientDB',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Carp		=> 0,
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	VERSION_FROM	=> 'lib/DBIx/HTML/ClientDB.pm',
);
