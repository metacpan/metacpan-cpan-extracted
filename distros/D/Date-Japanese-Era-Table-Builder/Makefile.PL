use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Date::Japanese::Era::Table::Builder',
    AUTHOR           => q{Williham Totland <williham.totland@gmail.com>},
    VERSION_FROM     => 'lib/Date/Japanese/Era/Table/Builder.pm',
    ABSTRACT_FROM    => 'lib/Date/Japanese/Era/Table/Builder.pm',
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
        'Date::Japanese::Era' => 0.06,
        'Date::Simple' => 2.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Date-Japanese-Era-Table-Builder-*' },
);
