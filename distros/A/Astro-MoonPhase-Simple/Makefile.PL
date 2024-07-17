use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Astro::MoonPhase::Simple',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Astro/MoonPhase/Simple.pm',
    ABSTRACT_FROM    => 'lib/Astro/MoonPhase/Simple.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    EXE_FILES => [
        'script/moon-phase-calculator.pl'
    ],
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Try::Tiny' => '0',
	'FindBin' => '0',
	'Config' => '0',
    },
    PREREQ_PM => {
	'DateTime' => '0',
	'DateTime::Format::ISO8601' => '0',
	'DateTime::TimeZone' => '0',
	'Geo::Location::TimeZone' => '0',
	'Astro::MoonPhase' => '0',
	'Exporter' => '0',
	'Data::Roundtrip' => '0',
	'Getopt::Long' => '0'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Astro-MoonPhase-Simple-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
