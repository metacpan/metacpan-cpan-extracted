#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'Algorithm::Odometer::Tiny',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'perl_5',
	VERSION_FROM   => 'lib/Algorithm/Odometer/Tiny.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/Algorithm/Odometer/Tiny.pm',
	MIN_PERL_VERSION => '5.6.0',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		provides     => {
			'Algorithm::Odometer::Tiny' => {
				file    => 'lib/Algorithm/Odometer/Tiny.pm',
				version => '0.02',
			},
			'Algorithm::Odometer::Gray' => {
				file    => 'lib/Algorithm/Odometer/Gray.pm',
				version => '0.02',
			},
		},
		no_index     => {
			file        => [
			],
		},
		resources    => {
			homepage    => 'https://github.com/haukex/Algorithm-Odometer-Tiny',
			repository  => {
				type       => 'git',
				url        => 'https://github.com/haukex/Algorithm-Odometer-Tiny.git',
				web        => 'https://github.com/haukex/Algorithm-Odometer-Tiny',
			},
			bugtracker  => {
				web        => 'https://github.com/haukex/Algorithm-Odometer-Tiny/issues',
				#mailto     => '',
			},
		},
		prereqs      => {
			runtime    => {
				recommends => { # "strongly encouraged and should be satisfied except in resource constrained environments"
				},
				suggests   => { # "optional, but are suggested for enhanced operation"
				},
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM      => {
		# CPAN - none
		# Perl core modules
		'Carp'                   => 0,
	},
	TEST_REQUIRES  => {
		# Perl core modules
		'Test::More'             => '1.302096',
		'File::Spec::Functions'  => 0,
		'File::Glob'             => 0,
		'List::Util'             => 0,
		'FindBin'                => 0,
		'Exporter'               => 0,
		'constant'               => 0,
		# note I haven't included modules needed for author tests here
	},
);
sub MY::postamble {
	return <<'MAKE_FRAG';
.PHONY: authorcover
authorcover: test
	cpanm Devel::Cover
	cover -test -coverage default,-pod
MAKE_FRAG
}
