use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Cache::Memcached::Sweet',
    AUTHOR           => q{Stig Palmquist <stig@stig.io>},
    VERSION_FROM     => 'lib/Cache/Memcached/Sweet.pm',
    ABSTRACT_FROM    => 'lib/Cache/Memcached/Sweet.pm',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Cache::Memcached' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Cache-Memcached-Sweet-*' },
);
