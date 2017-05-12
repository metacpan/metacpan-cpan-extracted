#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'Config::Perl',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'perl',
	VERSION_FROM   => 'lib/Config/Perl.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/Config/Perl.pm',
	MIN_PERL_VERSION => '5.6.0',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		resources    => {
			homepage    => 'https://github.com/haukex/Config-Perl',
			repository  => {
				type       => 'git',
				url        => 'https://github.com/haukex/Config-Perl.git',
				web        => 'https://github.com/haukex/Config-Perl',
			},
			bugtracker  => {
				web        => 'https://github.com/haukex/Config-Perl/issues',
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
		# CPAN
		'PPI'                    => 0,
		# Perl core modules
		'Exporter'               => 0,
		'Carp'                   => 0,
		'warnings::register'     => 0,
		'Data::Dumper'           => 0,
	},
	TEST_REQUIRES  => {
		# CPAN
		'Test::Fatal'            => 0,
		# Perl core modules
		'Test::More'             => 0,
		'FindBin'                => 0,
		'base'                   => 0, # "parent" pragma wasn't core until 5.10.1
		'File::Temp'             => 0,
		# note I haven't included modules needed for author tests here
	},
);
