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
		AUTHOR		=> 'B Jepson <bjepston@jepstone.net>',
		ABSTRACT	=> 'Generate a tree from a self-referential database table',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Tree-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-Tree',
	LICENSE		=> 'perl',
	NAME		=> 'DBIx::Tree',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'			=> 1.08,
		'DBD::SQLite'	=> 1.37,
		'DBI'			=> 1.622,
		'File::Spec'	=> 3.31,
		'File::Temp'	=> 0.22,
		'strict'		=> 0,
		'vars'			=> 0,
		'warnings'		=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/DBIx/Tree.pm',
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
				web => 'https://github.com/ronsavage/DBIx-Tree/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-Tree.git',
				web		=> 'https://github.com/ronsavage/DBIx-Tree',
			},
		},
	};
}

WriteMakefile(%params);
