use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Assert::Refute::T::Hash',
    AUTHOR           => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM     => 'lib/Assert/Refute/T/Hash.pm',
    ABSTRACT_FROM    => 'lib/Assert/Refute/T/Hash.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'     => 0.98, # done_testing + subtest
    },
    PREREQ_PM => {
        'Assert::Refute' => 0.16,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Assert-Refute-T-Hash-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/dallaylaen/assert-refute-t-extra/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/dallaylaen/assert-refute-t-extra.git',
                web => 'https://github.com/dallaylaen/assert-refute-t-extra',
            },
        },
        x_contributors => [
            # Alphabetically, with a comma at the end of line
        ],
    },
);
