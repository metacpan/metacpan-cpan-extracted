use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'BugCli',
	VERSION_FROM    => 'BugCli.pm',
	EXE_FILES       => ['bugcli.pl'],
	ABSTRACT	=> 'Command-line BugZilla client',
	AUTHOR		=> 'Sir Reflog',
	DISTNAME	=> 'BugCli',
	PREREQ_PM       => {

		'Getopt::Std'=>0,
		'FileHandle'=>0,
		'Term::Shell'=>0,
		'DBIx::SQLEngine'=>0,
		'Term::ANSIColor'=>0,
		'Text::Table'=>0,
		'Config::Tiny'=>0,
	}
);
