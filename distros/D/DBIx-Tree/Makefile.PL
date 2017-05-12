use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'B Jepson <bjepston@jepstone.net>',
		ABSTRACT => 'Generate a tree from a self-referential database table',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST DBIx-Tree-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'DBIx-Tree',
	NAME      => 'DBIx::Tree',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Carp'        => 1.08,
		'DBD::SQLite' => 1.37,
		'DBI'         => 1.622,
		'File::Spec'  => 3.31,
		'File::Temp'  => 0.22,
		'strict'      => 0,
		'Test::More'  => 0.94,
#		'Test::Pod'   => 1.45, # Make it optional. See t/pod.t
		'vars'        => 0,
		'warnings'    => 0,
	},
	VERSION_FROM => 'lib/DBIx/Tree.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		resources =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Tree',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
		},
	};
}

WriteMakefile(%params);
