use strict;
use warnings;

use ExtUtils::MakeMaker;

require 5.014002; # For the utf8 stuff.

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Manage a database of curated Perl modules',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CPAN-MetaCurator*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CPAN-MetaCurator',
	NAME      => 'CPAN::MetaCurator',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'boolean'								=> 0.46,
		'Config::Tiny'							=> 2.30,
		'DBI'									=> 1.645,
		'DBIx::Admin::CreateTable'				=> 2.11,
		'DBIx::Simple'							=> 1.37,
		'Data::Dumper::Concise'					=> 2.023,
		'DateTime'								=> 1.65,
		'DateTime::Tiny'						=> 1.07,
		'ExtUtils::MakeMaker'					=> 7.70,
		'File::Slurper'							=> 0.014,
		'File::Spec'							=> 3.90,
		'Getopt::Long'							=> 2.57,
		'HTML::Entities'						=> 3.83,
		'HTML::TreeBuilder'						=> 5.07,
		'lib'									=> 0.65,
		'Log::Handler'							=> 0.90,
		'Mojo::JSON'							=> undef,
		'Mojo::Log'								=> undef,
		'Moo'									=> 2.005005,
		'open'									=> 1.13,
		'parent'								=> 0.242,
		'Path::Tiny'							=> 0.146,
		'Pod::Usage'							=> 2.03,
		'strict'								=> 1.12,
		'Text::CSV::Encoded'					=> 0.25,
		'Types::Standard'						=> 2.006000,
		'warnings'						  		=> 1.58,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
	},
	VERSION_FROM => 'lib/CPAN/MetaCurator.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
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
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-MetaCurator',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/CPAN-MetaCurator.git',
				web		=> 'https://github.com/ronsavage/CPAN-MetaCurator',
			},
		},
	};
}

WriteMakefile(%params);
