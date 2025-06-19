use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Censor',
    AUTHOR           => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM     => 'lib/Data/Censor.pm',
    ABSTRACT_FROM    => 'lib/Data/Censor.pm',
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
        'Ref::Util' => 0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Censor-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/Data-Censor',
            bugtracker => 'https://github.com/bigpresh/Data-Censor/issues',
            homepage   => 'https://github.com/bigpresh/Data-Censor',
        },
    },
);
