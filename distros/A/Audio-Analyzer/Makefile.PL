use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Audio::Analyzer',
	VERSION_FROM => 'lib/Audio/Analyzer.pm',
	ABSTRACT_FROM       => 'lib/Audio/Analyzer.pm',
	PREREQ_PM => {
		'Test::More' => 0,
		'Math::FFT' => 0,
	},
);
