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
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Render any data structure as an object of type Tree::DAG_Node',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Data-RenderAsTree-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Data-RenderAsTree',
	NAME      => 'Data::RenderAsTree',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Data::Dumper::Concise' => 2.022,
		'Moo' => 2.000001,
		'Scalar::Util' => 1.42,
		'Set::Array' => 0.30,
		'strict' => 0,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.51,
		'Text::Truncate' => '1.06',
		'Tree::DAG_Node' => 1.26,
		'Types::Standard' => 1.000005,
		'warnings' => 0,
	},
	VERSION_FROM => 'lib/Data/RenderAsTree.pm',
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
		'version' => 2,
		},
		resources =>
		{
			'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-RenderAsTree',
			'license' => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				'type' => 'git',
				'url' => 'https://github.com/ronsavage/Data-RenderAsTree.git',
				'web' => 'https://github.com/ronsavage/Data-RenderAsTree',
			},
		},
	};
}

WriteMakefile(%params);
