use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Async::Chain',
    AUTHOR           => q{Anton Reznikov <a.reznikov@corp.mail.ru>},
    VERSION_FROM     => 'lib/Async/Chain.pm',
    ABSTRACT_FROM    => 'lib/Async/Chain.pm',
    LICENSE          => 'GPL_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
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
    clean => { FILES => 'Async-Chain-*' },
);
