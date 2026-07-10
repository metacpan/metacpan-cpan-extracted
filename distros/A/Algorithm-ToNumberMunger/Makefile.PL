use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME             => 'Algorithm::ToNumberMunger',
	AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM     => 'lib/Algorithm/ToNumberMunger.pm',
	ABSTRACT_FROM    => 'lib/Algorithm/ToNumberMunger.pm',
	LICENSE          => 'lgpl_2_1',
	MIN_PERL_VERSION => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Carp'         => '0',
		'Scalar::Util' => '0',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'https://github.com/vvelox/Algorithm-ToNumberMunger.git',
				web  => 'https://github.com/vvelox/Algorithm-ToNumberMunger',
			},
		},
		prereqs => {
			runtime => {
				# The 'datetime' munger loads Time::Piece lazily (core since
				# 5.9.5) and the IPv6 path in 'ip_class'/'cidr' loads Socket;
				# neither is needed unless that munger is used, so they are
				# recommendations, not hard requirements.
				recommends => {
					'Time::Piece' => '0',
				},
			},
		},
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Algorithm-ToNumberMunger-*' },
);

# The only XS in the dist is the FNV-1a used by the 'hash' munger (and the
# Shannon entropy used by 'entropy'); everything else is pure Perl and
# ToNumberMunger.pm carries a pure-Perl fallback. So the XS is strictly a
# speed-up: only build it when there is a compiler AND an ExtUtils::MakeMaker
# new enough for XSMULTI (per-.pm .xs files under lib/). Otherwise the module
# still installs and works, just without the C fast path.
my $can_xs = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 }
	&& eval { require ExtUtils::CBuilder; ExtUtils::CBuilder->new->have_compiler };
if ($can_xs) {
	$WriteMakefileArgs{XSMULTI} = 1;
} else {
	# No XS: make sure MakeMaker never tries to compile the stray .xs file.
	$WriteMakefileArgs{XS} = {};
	$WriteMakefileArgs{C}  = [];
}

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
