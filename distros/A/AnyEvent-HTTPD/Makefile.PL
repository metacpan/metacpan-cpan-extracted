use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::HTTPD',
    AUTHOR              => 'Robin Redeker <elmex@ta-sa.org>',
    VERSION_FROM        => 'lib/AnyEvent/HTTPD.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/HTTPD.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'AnyEvent'       => 0,
        'Object::Event'  => 0,
        'URI'            => 0,
        'Time::Local'    => 0,
        'common::sense'  => 0,
        'AnyEvent::HTTP' => 0,
        'bytes'          => 0,
        'Compress::Zlib' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             PREOP => 'pod2text lib/AnyEvent/HTTPD.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'AnyEvent-HTTPD-*' },
);
