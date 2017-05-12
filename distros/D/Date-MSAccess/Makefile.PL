use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'Convert MS Access dates into YYYYMMDD',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST Date-MSAccess-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'Date-MSAccess',
	NAME			=> 'Date::MSAccess',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Date::Calc	=> 5.3,
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	VERSION_FROM	=> 'lib/Date/MSAccess.pm',
);
