use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
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
		'Brannigan'							=> 1.1,
		'Capture::Tiny'						=> 0.46,
		'CGI'								=> 3.49,
		'CGI::Application'					=> 4.31,
		'CGI::Application::Dispatch'		=> 2.17,
		'CGI::Application::Dispatch::PSGI'	=> 3.12,
		'CGI::Untaint'						=> 1.26,
		'Config::Tiny'						=> 2.23,
		'Data::Session'						=> 1.17,
		'Date::Format'						=> 2.24,
		'DBD::SQLite'						=> 1.54,
		'DBI'								=> 1.611,
		'DBIx::Admin::CreateTable'			=> 2.10,
		'DBIx::Admin::TableInfo'			=> 3.03,
		'DBIx::Simple'						=> 1.35,
		'File::Path'						=> 2.08,
		'File::Spec'						=> 3.31,
		'File::Slurper'						=> 0.010,
		'FindBin'							=> 1.51,
		'JSON::XS'							=> 3.02,
		'Lingua::EN::Inflect::Number'		=> 1.11,
		'Log::Handler'						=> 0.88,
		'Moo'								=> 2.003002,
		'parent'							=> 0.234,
		'Path::Class'						=> 0.37,
		'Plack::Builder'					=> 0,
		'strict'							=> 0,
		'String::Dirify'					=> 1.03,
		'Text::Xslate'						=> 3.4.0,
		'Tree'								=> 1.10,
		'Tree::DAG_Node'					=> 1.29,
		'Tree::DAG_Node::Persist'			=> 1.12,
		'Try::Tiny'							=> 0.28,
		'Types::Standard'					=> 1.000005,
		'warnings'							=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/App/Office/CMS.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources =>
		{
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Office-CMS',
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/App-Office-CMS.git',
				web		=> 'https://github.com/ronsavage/App-Office-CMS',
			},
		},
	};
}

WriteMakefile(%params);
