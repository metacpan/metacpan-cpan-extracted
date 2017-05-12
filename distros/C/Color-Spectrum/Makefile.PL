use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Color::Spectrum',
    AUTHOR           => q{jeffa <info+cpan@unlocalhost.com>},
    VERSION_FROM     => 'lib/Color/Spectrum.pm',
    ABSTRACT_FROM    => 'lib/Color/Spectrum.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Color::Library' => 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'https://github.com/jeffa/Color-Spectrum',
                repository => 'https://github.com/jeffa/Color-Spectrum.git',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Color-Spectrum-*' },
);
