use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Manage a file of DSNs, for both testing and production',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Admin::DSNManager-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'DBIx-Admin-DSNManager',
	NAME      => 'DBIx::Admin::DSNManager',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Config::Tiny'  => 2.12,
		'File::Slurp'   => 9999.13,
		'File::Spec'    => 3.31,
		'File::Temp'    => 0.22,
		'Moo'           => 1.004002,
		'Test::More'    => 0.96,
#		'Test::Pod'     => 1.45, # Make it optional. See t/pod.t
		'Test::Version' => 1.002003,
		'Try::Tiny'     => 0.06,
		'strict'        => 0,
		'warnings'      => 0,
	},
	VERSION_FROM => 'lib/DBIx/Admin/DSNManager.pm',
);
