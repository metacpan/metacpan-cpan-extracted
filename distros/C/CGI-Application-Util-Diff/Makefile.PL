use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Diff 2 directories or files, or run other commands',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Application-Util-Diff-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Application-Util-Diff',
	NAME      => 'CGI::Application::Util::Diff',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Algorithm::Diff             => 0,
		Carp                        => 0,
		CGI                         => 0,
		CGI::Application            => 0,
		CGI::Application::Dispatch  => 0,
		Config::Tiny                => 0,
		DBD::CSV                    => 0, # For default logging.
		DBI                         => 0, # For default logging.
		FCGI::ProcManager           => 0,
		File::stat                  => 0,
		Hash::FieldHash             => 0,
		HTML::Entities::Interpolate => 0,
		HTML::Template              => 0,
		IPC::Capture                => 0,
		JSON::XS                    => 0,
		Path::Class                 => 0,
		Test::More                  => 0,
		Test::Pod                   => 0,
	},
	VERSION_FROM => 'lib/CGI/Application/Util/Diff.pm',
);
