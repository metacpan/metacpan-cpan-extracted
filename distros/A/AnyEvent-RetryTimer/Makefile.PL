use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::RetryTimer',
    AUTHOR              => 'Robin Redeker <elmex@ta-sa.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/AnyEvent/RetryTimer.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/RetryTimer.pm',
    PL_FILES            => {},
    test                => { TESTS => "t/*.t t/methds/*.t" },
    PREREQ_PM => {
        'AnyEvent'      => 3.5,
        'common::sense' => 0,
        'Scalar::Util'  => 0,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX   => 'gz',
       PREOP => 'pod2text lib/AnyEvent/RetryTimer.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'AnyEvent-RetryTimer' },
);
