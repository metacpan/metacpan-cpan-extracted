use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::IRC',
    AUTHOR              => 'Robin Redeker <elmex@ta-sa.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/AnyEvent/IRC.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/IRC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'AnyEvent'      => '5.111',
        'Object::Event' => '0.6',
        'common::sense' => 0,
        'Scalar::Util'  => 0,
        'Encode'        => 0,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX => 'gz',
       PREOP => 'pod2text lib/AnyEvent/IRC.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'AnyEvent-IRC-*' },
);
