use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Algorithm::Classifier::IsolationForest',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Algorithm/Classifier/IsolationForest.pm',
	ABSTRACT_FROM      => 'lib/Algorithm/Classifier/IsolationForest.pm',
	LICENSE            => 'lgpl_2_1',
	MIN_PERL_VERSION   => '5.006',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => ['src_bin/iforest'],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
		'File::Temp' => '0',
		'JSON::PP'   => '0',
		'List::Util' => '0',
	},
	PREREQ_PM => {
		'App::Cmd'     => '0',
		'Carp'         => '0',
		'Config'       => '0',
		'File::Slurp'  => '0',
		'File::Spec'   => '0',
		'File::Temp'   => '0',
		'JSON::PP'     => '0',
		'List::Util'   => '0',
		'POSIX'        => '0',
		'Scalar::Util' => '0',
		'Storable'     => '0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Algorithm-Classifier-IsolationForest-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		prereqs     => {
			runtime => {
				# Inline / Inline::C unlock the native scoring backend
				# (and OpenMP parallel tree-walk if libgomp is available
				# at build time).  The pure-Perl fallback works without
				# them, just slower, so they are recommends rather than
				# hard requires.
				recommends => {
					'Inline'    => '0',
					'Inline::C' => '0',
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:LilithSec/Algorithm-Classifier-IsolationForest.git',
				web  => 'https://github.com/LilithSec/Algorithm-Classifier-IsolationForest',
			},
		},
	}
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
