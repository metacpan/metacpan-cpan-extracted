use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::MyFirstModule::DRPENGUIN',
    AUTHOR           => q{Leo Chan <penguin02007@gmail.com>},
    VERSION_FROM     => 'lib/Acme/MyFirstModule/DRPENGUIN.pm',
    ABSTRACT_FROM    => 'lib/Acme/MyFirstModule/DRPENGUIN.pm',
    LICENSE          => 'artistic_2',
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
    clean => { FILES => 'Acme-MyFirstModule-DRPENGUIN-*' },
);
