use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME				=> 'App::nodie',
	VERSION_FROM		=> 'lib/App/nodie.pm',
	MIN_PERL_VERSION	=> '5.010001',
	PREREQ_PM			=> {
		'Scalar::Util'	=> '1.47',
		'Lazy::Utils'	=> '1.21',
	},
	EXE_FILES			=> [qw(
		lib/App/nodie/nodie.pl
		lib/App/nodie/nodie
	)],
	AUTHOR				=> 'Orkun Karaduman <orkunkaraduman@gmail.com>',
	ABSTRACT			=> 'runs command again when its dead',
	LICENSE				=> 'gpl_3',
	META_MERGE			=> {
		'meta-spec'		=> {
			version		=> 2,
		},
		resources		=> {
			homepage	=> 'https://github.com/orkunkaraduman/App-nodie/tree/master',
			license		=> 'https://www.gnu.org/licenses/gpl-3.0.html',
			repository	=> {
				type	=> 'git',
				url		=> 'git://git@github.com:orkunkaraduman/App-nodie.git',
				web		=> 'https://github.com/orkunkaraduman/App-nodie',
			},
			bugtracker => {
				web    => 'https://github.com/orkunkaraduman/App-nodie/issues',
				mailto => 'bug-App-nodie@rt.cpan.org',
			},
		},
	},
);
