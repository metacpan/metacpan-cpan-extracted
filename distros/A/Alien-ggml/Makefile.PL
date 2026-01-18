use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my %WriteMakefileArgs = (
    DISTNAME         => 'Alien-ggml',
    NAME             => 'Alien::ggml',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Alien/ggml.pm',
    ABSTRACT_FROM    => 'lib/Alien/ggml.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'Alien::Build::MM'    => '2.38',
        'Alien::Build'        => '2.38',
        'Alien::Build::Plugin::Build::CMake' => '0.99',
        'ExtUtils::MakeMaker' => '6.52',
    },
    BUILD_REQUIRES => {
        'Alien::Build' => '2.38',
    },
    TEST_REQUIRES => {
        'Test::More'  => '0.96',
        'Test::Alien' => '2.38',
    },
    PREREQ_PM => {
        'Alien::Base' => '2.38',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/lnation/Alien-ggml.git',
                web  => 'https://github.com/lnation/Alien-ggml',
            },
            bugtracker => {
                web => 'https://github.com/lnation/Alien-ggml/issues',
            },
        },
        x_contributors => [
            'LNATION <email@lnation.org>',
        ],
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Alien-ggml-* _alien' },
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
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

my $abmm = Alien::Build::MM->new;
WriteMakefile($abmm->mm_args(%WriteMakefileArgs));

sub MY::postamble {
    $abmm->mm_postamble;
}
