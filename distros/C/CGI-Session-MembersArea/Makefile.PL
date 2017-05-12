use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'A resource guardian based on CGI::Session',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Session-MembersArea-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Session-MembersArea',
	NAME      => 'CGI::Session::MembersArea',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Carp         => 0,
		CGI::Session => 0,
		DBI          => 0,
		Test::More   => 0,
		Test::Pod    => 0,
	},
	VERSION_FROM	=> 'lib/CGI/Session/MembersArea.pm',
);
