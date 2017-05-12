use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Multihash',
    AUTHOR           => q{Radek Slupik <rightfold@gmail.com>},
    VERSION_FROM     => 'lib/Data/Multihash.pm',
    ABSTRACT_FROM    => 'lib/Data/Multihash.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Set::Object' => 1.34,
    },
    META_MERGE => {
        resources => {
            repository => "https://github.com/rightfold/data-multihash",
            bugtracker => "https://github.com/rightfold/data-multihash/issues",
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Multihash-*' },
);
