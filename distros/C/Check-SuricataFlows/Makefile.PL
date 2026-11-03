use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Check::SuricataFlows',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Check/SuricataFlows.pm',
	ABSTRACT_FROM      => 'lib/Check/SuricataFlows.pm',
	LICENSE            => 'gpl_2',
	MIN_PERL_VERSION   => '5.006',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => ['src_bin/check_suricataflows'],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'JSON'                => 0,
		'File::ReadBackwards' => 0,
		'Regexp::IPv6'        => 0,
		'Regexp::IPv4'        => 0,
		'NetAddr::IP'         => 0,
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Check-SuricataFlows-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		# Monitoring::Sneck::Checks::suricata_flows is only loaded by Monitoring::Sneck::Checks, so
		# it is optional, only needed for running this in process from sneck or through sneck_check
		prereqs => {
			runtime => {
				recommends => {
					'Monitoring::Sneck::Checks' => '0.0.1',
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:VVelox/Check-SuricataFlows.git',
				web  => 'https://github.com/VVelox/Check-SuricataFlows',
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
