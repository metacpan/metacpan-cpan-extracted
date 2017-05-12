
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Daemon::Generic',
	DISTNAME	=> 'Daemon-Generic',
	VERSION_FROM	=> 'lib/Daemon/Generic.pm',
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'Getopt::Long'		=> 0,
		'File::Flock'		=> 2013.06,
		'File::Slurp'		=> 0,
		'Text::Wrap'		=> 0,
		'Cwd'			=> 0,
		'File::Basename'	=> 0,
	},
	BUILD_REQUIRES	=> {
		'Time::HiRes'		=> 0,
		'Event'			=> 0,
		'AnyEvent'		=> 0,
		'Eval::LineNumbers'	=> 0,
	},
	($] >= 5.005 
		?	
			(
				ABSTRACT	=> 'framework to provide start/stop/reload for a daemon',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/Daemon-Generic',
					},
				},
			) 
		: ()
	),
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/Daemon/Generic.pod
	pod2text  lib/Daemon/Generic.pod >README

END_OF_POSTAMBLE
}
