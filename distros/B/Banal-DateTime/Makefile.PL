use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Banal::DateTime',
    AUTHOR           => q{"aulusoy" <"dev (at) ulusoy.name">},
    VERSION_FROM     => 'lib/Banal/DateTime.pm',
    ABSTRACT_FROM    => 'lib/Banal/DateTime.pm',
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
        'DateTime'              => 1.00,
    },
    
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Banal-DateTime-*' },
);
