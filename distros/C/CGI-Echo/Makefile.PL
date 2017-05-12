use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Echo form data to test form design',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST CGI-Echo-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'CGI-Echo',
	NAME			=> 'CGI::Echo',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Carp		=> 0,
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	VERSION_FROM	=> 'lib/CGI/Echo.pm',
);
