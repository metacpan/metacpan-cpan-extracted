use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::EditText',
    AUTHOR              => 'Robin Redeker <elmex@ta-sa.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/AnyEvent/EditText.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/EditText.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'AnyEvent'   => 0,
        'File::Temp' => 0,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX   => 'gz',
       PREOP => 'pod2text lib/AnyEvent/EditText.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'AnyEvent-EditText-*' },
);
