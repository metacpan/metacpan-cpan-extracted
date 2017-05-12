use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AnyEvent::HTTPD::CookiePatch',
    AUTHOR           => q{Cindy Wang (CindyLinz)},
    VERSION_FROM     => 'lib/AnyEvent/HTTPD/CookiePatch.pm',
    ABSTRACT_FROM    => 'lib/AnyEvent/HTTPD/CookiePatch.pm',
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
        version => 0,
        'AnyEvent::HTTPD' => 0,
        'AnyEvent::HTTPD::SendMultiHeaderPatch' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'AnyEvent-HTTPD-CookiePatch-*' },
);
