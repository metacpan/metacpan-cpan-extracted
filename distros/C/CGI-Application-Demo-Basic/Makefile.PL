use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'A CGI::Application demonstration module',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Application-Demo-Basic-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Application-Demo-Basic',
	NAME      => 'CGI::Application::Demo::Basic',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		CGI::Application                      => 0,
		CGI::Application::Plugin::LogDispatch => 0,
		CGI::Application::Plugin::Session     => 0,
		CGI::Simple                           => 0,
		Class::DBI                            => 0,
		Class::DBI::Loader                    => 0,
		Class::DBI::SQLite                    => 0.11,
		Config::Tiny                          => 2.12,
		DBIx::Admin::CreateTable              => 2.06,
		File::Slurp                           => 9999.13,
		FindBin::Real                         => 0,
		Hash::FieldHash                       => 0.10,
		HTML::Template                        => 0,
		Log::Dispatch::DBI                    => 0,
		Test::More                            => 0,
		Test::Pod                             => 0,
	},
	VERSION_FROM => 'lib/CGI/Application/Demo/Basic.pm',
);
