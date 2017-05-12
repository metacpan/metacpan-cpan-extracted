use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Context::Micro',
    AUTHOR           => q{ytnobody <ytnobody aaatttt gmail>},
    VERSION_FROM     => 'lib/Context/Micro.pm',
    ABSTRACT_FROM    => 'lib/Context/Micro.pm',
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
        # it's empty!
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Context-Micro-*' },
);
