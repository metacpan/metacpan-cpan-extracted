use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Async::Stream',
    AUTHOR           => q{Kirill Sysoev <k.sysoev@me.com>},
    VERSION_FROM     => 'lib/Async/Stream.pm',
    ABSTRACT_FROM    => 'lib/Async/Stream.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Scalar::Util' => '0',
        'Carp'         => '0',
        'Exporter'     => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Async-Stream-*' },
);
