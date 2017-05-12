use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
	 'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
	 'ABSTRACT' => 'A CGI::Session driver for ODBC',
    ) : (),
	clean =>
	{
	 FILES => 'blib/* Makefile MANIFEST CGI-Session-Driver-odbc-*'
	},
	dist =>
	{
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Session-Driver-odbc',
	NAME      => 'CGI::Session::Driver::odbc',
	PL_FILES  => {},
	PREREQ_PM =>
	{
	 Carp         => 0,
	 CGI::Session => '4.42',
	 DBI          => 1.609,
	 Test::More   => 0.94,
	 Test::Pod    => 1.41,
	},
	VERSION_FROM => 'lib/CGI/Session/Driver/odbc.pm',
);
