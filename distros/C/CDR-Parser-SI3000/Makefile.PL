use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CDR::Parser::SI3000',
    AUTHOR           => q{Sergey Leschenko <sergle.ua@gmail.com>},
    VERSION_FROM     => 'lib/CDR/Parser/SI3000.pm',
    ABSTRACT_FROM    => 'lib/CDR/Parser/SI3000.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CDR-Parser-SI3000-*' },
);
