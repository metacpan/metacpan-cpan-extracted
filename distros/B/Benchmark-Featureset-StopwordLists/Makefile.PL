use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
	AUTHOR   => 'Ron Savage (ron@savage.net.au)',
	ABSTRACT => 'Compare various stopword list modules',
	) : (),
	clean =>
	{
	FILES => 'blib/* Makefile MANIFEST Benchmark-Featureset-StopwordLists-*'
	},
	dist =>
	{
	COMPRESS => 'gzip',
	SUFFIX   => 'gz'
	},
	DISTNAME  => 'Benchmark-Featureset-StopwordLists',
	NAME      => 'Benchmark::Featureset::StopwordLists',
	LICENSE   => 'artistic_2',
# Next line runs copy.config.pl when user runs 'make'.
# Warning: '...' => 0 is OK but => '' or undef are ignored.
	PL_FILES  => {'scripts/copy.config.pl' => 'Copying...'},
	PREREQ_PM =>
	{
		'Config' => 5.020002,
		'Config::Tiny' => 2.13,
		'Date::Simple' => 3.03,
		'File::Copy' => 2.21,
		'File::HomeDir' => 0.99,
		'File::Slurp' => 9999.19,
		'Lingua::EN::StopWordList' => 1.01,
		'Lingua::EN::StopWords' => 0.1,
		'Lingua::StopWords' => 0.09,
		'Module::Version' => 0.12,
		'Moo' => 2.000002,
		'Path::Class' => 0.24,
		'strict' => 1.04,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'Text::Xslate' => 1.5010,
		'Types::Standard' => 1.000005,
		'warnings' => 1.12,
	},
	VERSION_FROM => 'lib/Benchmark/Featureset/StopwordLists.pm',
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
		resources   =>
		{
			'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Benchmark-Featureset-StopwordLists',
			'license'    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				'type' => 'git',
				'url'  => 'https://github.com/ronsavage/Benchmark-Featureset-StopwordLists.git',
				'web'  => 'https://github.com/ronsavage/Benchmark-Featureset-StopwordLists',
			},
		},
	};
}

WriteMakefile(%params);
