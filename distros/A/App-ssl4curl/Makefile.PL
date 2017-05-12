use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::ssl4curl',
    AUTHOR           => q{Zdenek Bohunek <zdenek@cpan.org>},
    VERSION_FROM     => 'lib/App/ssl4curl.pm',
    ABSTRACT_FROM    => 'lib/App/ssl4curl.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    'EXE_FILES'      => ['ssl4curl'],
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
    clean => { FILES => 'App-ssl4curl-*' },
);
