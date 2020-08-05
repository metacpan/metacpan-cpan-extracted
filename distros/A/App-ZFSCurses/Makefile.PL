use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'App::ZFSCurses',
	AUTHOR       => 'Patrice Clement <monsieurp@cpan.org>',
	VERSION_FROM => 'lib/App/ZFSCurses.pm',
	ABSTRACT     => 'curses UI to query and modify a ZFS dataset properties.',
	LICENSE      => 'bsd',
	EXE_FILES    => [ 'script/zfscurses' ],
	MIN_PERL_VERSION   => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Curses::UI'   => '0.9609',
		'Curses'       => '1.36',
		'Getopt::Long' => '0',
		'Pod::Usage'   => '0'
	},
	TEST_REQUIRES => {
		'Test::More'    => '0',
		'Capture::Tiny' => '0',
	},
	META_MERGE => {
		name        => 'App-ZFSCurses',
		licence     => [ 'bsd' ],
		'meta-spec' => { version => 2 },
		resources   => {
			homepage   => 'https://gitlab.com/monsieurp/App-ZFSCurses',
			license    => [ 'https://opensource.org/licenses/BSD-3-Clause' ],
			repository => {
				type => 'git',
				url  => 'https://gitlab.com/monsieurp/App-ZFSCurses.git',
				web  => 'https://gitlab.com/monsieurp/App-ZFSCurses'
			},
			bugtracker => {
				web => 'https://gitlab.com/monsieurp/App-ZFSCurses/-/issues'
			},
		},
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'App-ZFSCurses-*' },
);
