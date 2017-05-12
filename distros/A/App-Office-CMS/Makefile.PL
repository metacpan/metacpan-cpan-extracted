\use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'The Canny, Microlight and Simple CMS',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST App-Office-CMS-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'App-Office-CMS',
	NAME      => 'App::Office::CMS',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Any::Moose                 => 0.13,
		Brannigan                  => 0.5,
		Capture::Tiny              => 0.08,
		CGI                        => 3.49,
		CGI::Application           => 4.31,
		CGI::Application::Dispatch => 2.17,
		CGI::Untaint               => 1.26,
		common::sense              => 3.0,
		Config::Tiny               => 2.12,
		Data::Session              => 1.01,
		Date::Format               => 2.24,
		DBD::SQLite                => 1.29,
		DBI                        => 1.611,
		DBIx::Admin::CreateTable   => 2.04,
		File::Path                 => 2.08,
		File::Spec                 => 3.31,
		File::Slurp                => 9999.13,
		FindBin                    => 1.49,
		JSON::XS                   => 2.29,
		Log::Handler               => 0.68,
		parent                     => 0.218,
		Path::Class                => 0.18,
		String::Dirify             => 1.01,
		Test::Simple               => 0.94,
		Test::Pod                  => 1.41,
		Tree::DAG_Node             => 1.06,
		Tree::DAG_Node::Persist    => 1.03,
		Try::Tiny                  => 0.06,
		Text::Xslate               => 0.1051,
	},
	VERSION_FROM => 'lib/App/Office/CMS.pm',
);
