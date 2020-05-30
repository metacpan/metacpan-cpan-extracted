use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'CSV::Reader',
	'AUTHOR' => 'Craig Manley',
	'ABSTRACT' => 'Simple CSV reader class that uses Text::CSV internally.',
	#'MIN_PERL_VERSION' => '5.013000',
	'VERSION_FROM' => 'lib/CSV/Reader.pm',
	'BUILD_REQUIRES' => {
		'ExtUtils::MakeMaker'	=> 6.48,
		'Test::More'			=> 0,
	},
	'PREREQ_PM' =>	{
		'File::BOM'		=> 0,
		'Text::CSV'		=> 0,
		'Tie::IxHash'	=> 0,
		'Test::More'	=> 0,
	},
	'MIN_PERL_VERSION'	=> 5.010000,
	'LICENSE' => 'perl_5',
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	'META_MERGE' => {
		'meta-spec' => { 'version' => 2 },
		'resources' => {
			'repository' => {
				'type' => 'git',
				'url'  => 'https://github.com/cmanley/p5-CSV-Reader.git',
				'web'  => 'https://github.com/cmanley/p5-CSV-Reader/',
			},
			'bugtracker' => {'web' => 'https://github.com/cmanley/p5-CSV-Reader/issues'},
			#homepage   => 'https://craigmanley.com/',
		},
	},
);
