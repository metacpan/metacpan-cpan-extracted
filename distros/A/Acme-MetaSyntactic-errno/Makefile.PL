use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Acme::MetaSyntactic::errno',
    AUTHOR         => 'Philippe Bruhat (BooK) <book@cpan.org>',
    VERSION_FROM   => 'lib/Acme/MetaSyntactic/errno.pm',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'          => 0.94,
        'Test::MetaSyntactic' => 1.001,
    },
    PREREQ_PM  => {
        'Acme::MetaSyntactic' => 1.001,
    },
    MIN_PERL_VERSION => 5.006002,
    META_MERGE => {
        resources => {
            repository => 'http://github.com/book/Acme-MetaSyntactic-errno/',
        },
    },
    LICENSE   => 'perl',
    EXE_FILES => [ ],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-MetaSyntactic-errno-*' },
);
