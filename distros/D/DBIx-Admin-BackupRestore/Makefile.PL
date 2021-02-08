use ExtUtils::MakeMaker;

require 5.005_62;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Back-up all tables in a db to XML, and restore them',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Admin-BackupRestore-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-Admin-BackupRestore',
	LICENSE		=> 'perl',
	NAME		=> 'DBIx::Admin::BackupRestore',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'				=> 0,
		'XML::Parser'		=> 0,
		'XML::Records'		=> 0,
		'XML::TokeParser'	=> 0,
	},
	TEST_REQUIRES =>
	{
		'boolean'		=> 0.46,
		'Error'			=> 0,
		'Test::More'	=> 1.001014,
	},
	VERSION_FROM	=> 'lib/DBIx/Admin/BackupRestore.pm',
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
				web => 'https://github.com/ronsavage/DBIx-Admin-BackupRestore/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-Admin-BackupRestore.git',
				web		=> 'https://github.com/ronsavage/DBIx-Admin-BackupRestore',
			},
		},
	};
}

WriteMakefile(%params);
