use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Catalyst::Blinker',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'Blinker.pm',
	VERSION_FROM  => 'Blinker.pm',
	PREREQ_PM     => { Prima => 0, Catalyst => '5.9' },
	META_MERGE        => {
		resources => {
			repository => 'https://github.com/dk/catalyst-blinker',
		},
	},
);
