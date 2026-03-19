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
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Manage a database of Perl packages',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CPAN-MetaPackager*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'CPAN-MetaPackager',
	LICENSE		=> 'perl',
	NAME		=> 'CPAN::MetaPackager',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'boolean'					=> 0.46,
		'Config::Tiny'				=> 2.30,
		'Data::Dumper::Concise'		=> 2.023,
		'DateTime::Tiny'			=> 1.07,
		'DBI'						=> 1.645,
		'DBIx::Admin::CreateTable'	=> 2.11,
		'DBIx::Simple'				=> 1.37,
		'ExtUtils::MakeMaker'		=> 7.70,
		'File::Slurper'				=> 0.014,
		'File::Spec'				=> 3.90,
		'Getopt::Long'				=> 2.57,
		'Mojo::Log'					=> undef,
		'Moo'						=> 2.005005,
		'parent'					=> 0.242,
		'perl'						=> 5.36,
		'Pod::Usage'				=> 2.03,
		'strict'					=> 1.12,
		'Types::Standard'			=> 2.006000,
		'warnings'					=> 1.58,
	},
	TEST_REQUIRES =>
	{
		'Test::CPAN::Changes'			=> 0.500005,
		'Test::Changes::Strict::Simple'	=> 0.01,
		'Test::More'					=> 1.001002,
	},
	VERSION_FROM => 'lib/CPAN/MetaPackager.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-MetaPackager',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/CPAN-MetaPackager.git',
				web		=> 'https://github.com/ronsavage/CPAN-MetaPackager',
			},
		},
	};
}

WriteMakefile(%params);
