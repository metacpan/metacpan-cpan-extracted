use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
	 AUTHOR   => 'Ron Savage (ron@savage.net.au)',
	 ABSTRACT => 'Generate a set of CGI::Application-based classes',
    ) : (),
	clean =>
	{
	 FILES => 'blib/* Makefile MANIFEST CGI-Application-Bouquet-Rose-*'
	},
	dist =>
	{
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI::Application::Bouquet::Rose',
	NAME      => 'CGI-Application-Bouquet-Rose',
	PL_FILES  => {},
	PREREQ_PM =>
	{
	 Carp             => 0,
	 Config::IniFiles => 0,
	 File::Copy       => 0,
	 File::Path       => 0,
	 File::Spec       => 0,
	 HTML::Template   => 0,
	},
	VERSION_FROM => 'lib/CGI/Application/Bouquet/Rose.pm',
);
