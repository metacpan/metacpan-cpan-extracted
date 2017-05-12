use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
	 AUTHOR   => 'Ron Savage (ron@savage.net.au)',
	 ABSTRACT => 'A search engine using CGI::Application, AJAX and JSON',
    ) : (),
	clean =>
	{
	 FILES => 'blib/* Makefile MANIFEST CGI-Application-Demo-Ajax-*'
	},
	dist =>
	{
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Application-Demo-Ajax',
	NAME      => 'CGI::Application::Demo::Ajax',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Carp             => 0,
		CGI::Application => 0,
		Config::Tiny     => 0,
		DBD::CSV         => 0,
		DBI              => 0,
		HTML::Template   => 0,
		JSON::XS         => 0,
		Test::More       => 0,
		Test::Pod        => 0,
	},
	VERSION_FROM => 'lib/CGI/Application/Demo/Ajax.pm',
);
