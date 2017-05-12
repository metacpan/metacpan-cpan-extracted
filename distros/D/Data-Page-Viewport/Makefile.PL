use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Move thru data a page, or just an item, at a time',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST Data-Page-Viewport-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'Data-Page-Viewport',
	NAME			=> 'Data::Page::Viewport',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Set::Window	=> 0,
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	VERSION_FROM	=> 'lib/Data/Page/Viewport.pm',
);
