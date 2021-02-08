use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Manage a file of DSNs, for both testing and production',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Admin::DSNManager-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'DBIx-Admin-DSNManager',
	LICENSE		=> 'perl',
	NAME		=> 'DBIx::Admin::DSNManager',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Config::Tiny'  => 2.12,
		'File::Slurp'   => 9999.13,
		'File::Spec'    => 3.31,
		'File::Temp'    => 0.22,
		'Moo'           => 1.004002,
		'Try::Tiny'     => 0.06,
		'strict'        => 0,
		'warnings'      => 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Version' => 1.002003,
	},
	VERSION_FROM	=> 'lib/DBIx/Admin/DSNManager.pm',
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
		resources =>
		{
			bugtracker =>
			{
				web => 'https://github.com/ronsavage/DBIx-Admin-DSNManager/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/DBIx-Admin-DSNManager.git',
				web		=> 'https://github.com/ronsavage/DBIx-Admin-DSNManager',
			},
		},
	};
}

WriteMakefile(%params);
