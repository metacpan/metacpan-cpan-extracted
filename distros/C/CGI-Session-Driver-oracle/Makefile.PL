use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'A CGI::Session driver for Oracle',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Session-Driver-oracle-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Session-Driver-oracle',
	NAME      => 'CGI::Session::Driver::oracle',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Carp                      => 0,
		CGI::Session::Driver::DBI => '4.21',
		DBI                       => 1.609,
		Test::More                => 0,
		Test::Pod                 => 0,
	},
	VERSION_FROM => 'lib/CGI/Session/Driver/oracle.pm',
);
