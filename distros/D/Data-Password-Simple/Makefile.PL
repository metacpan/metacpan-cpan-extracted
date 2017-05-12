use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Password::Simple',
    AUTHOR           => q{Ross Hayes <ross@abablabab.co.uk>},
    VERSION_FROM     => 'lib/Data/Password/Simple.pm',
    ABSTRACT_FROM    => 'lib/Data/Password/Simple.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    PREREQ_PM => {
        Carp    =>  0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Password-Simple-*' },
);
