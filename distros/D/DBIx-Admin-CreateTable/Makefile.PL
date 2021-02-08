use strict;
use warnings;

use ExtUtils::MakeMaker;

print "The tests in t/syntax.error.t will only by run if \$DBI_DSN, \$DBI_USER and \$DBI_PASS are defined. \n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Create and drop tables, primary indexes, and sequences',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Admin-CreateTable-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-Admin-CreateTable',
	LICENSE		=> 'perl',
	NAME		=> 'DBIx::Admin::CreateTable',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'DBI'           => 0,
		'Moo'           => 1.004002,
		'strict'        => 0,
		'warnings'      => 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Version'	=> 1.002003,
	},
	VERSION_FROM	=> 'lib/DBIx/Admin/CreateTable.pm',
	INSTALLDIRS		=> 'site',
	EXE_FILES		=> [],
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
			bugtracker =>
			{
				web => 'https://github.com/ronsavage/DBIx-Admin-CreateTable/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-Admin-CreateTable.git',
				web		=> 'https://github.com/ronsavage/DBIx-Admin-CreateTable',
			},
		},
	};
}

WriteMakefile(%params);
