use ExtUtils::MakeMaker;

WriteMakefile (
	NAME		=> 'Config::Nested',
	VERSION_FROM	=> 'lib/Config/Nested.pm',
	DISTNAME	=> "Config-Nested",
	dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},

	PREREQ_PM  => {
		'Parse::RecDescent'	=> 1,
		'Storable'		=> 2,
		'Data::Dumper'		=> 1,
		'Text::Abbrev'		=> 1,
		'Carp'			=> 1,
		},

);

