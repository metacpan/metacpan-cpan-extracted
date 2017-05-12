use strict;
use warnings;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'A wrapper for all of table_info(), column_info(), *_key_info()',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Admin-TableInfo-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-Admin-TableInfo',
	NAME		=> 'DBIx::Admin::TableInfo',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Data::Dumper::Concise'			=> 2.022,
		'DBI'							=> 0,
		'DBIx::Admin::CreateTable'		=> 2.10,
		'DBIx::Admin::DSNManager'		=> 2.01,
		'Lingua::EN::PluralToSingular'	=> 0.18,
		'Moo'							=> 2.002004,
		'strict'						=> 0,
		'Text::Table::Manifold'			=> 1.00,
		'warnings'						=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.302052,
		'Test::Pod'		=> 1.51,
	},
	VERSION_FROM => 'lib/DBIx/Admin/TableInfo.pm',
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
		resources   =>
		{
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Admin-TableInfo',
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-Admin-TableInfo.git',
				web		=> 'https://github.com/ronsavage/DBIx-Admin-TableInfo',
			},
		},
	};
}

WriteMakefile(%params);
