use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Convert SQL to 2 linked HTML popup menus',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST DBIx-HTML-LinkedMenus-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'DBIx-HTML-LinkedMenus',
	NAME			=> 'DBIx::HTML::LinkedMenus',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Carp		=> 0,
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	VERSION_FROM	=> 'lib/DBIx/HTML/LinkedMenus.pm',
);
