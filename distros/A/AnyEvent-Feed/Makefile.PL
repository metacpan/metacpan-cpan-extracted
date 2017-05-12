use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::Feed',
    AUTHOR              => 'Robin Redeker <elmex@x-paste.de>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/AnyEvent/Feed.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/Feed.pm',
    PL_FILES            => {},
    test                => { TESTS => "t/*.t t/methds/*.t" },
    PREREQ_PM => {
        'Test::More'     => 0,
        'AnyEvent'       => 3.5,
        'MIME::Base64'   => 0,
        'AnyEvent::HTTP' => 0,
        'Digest::SHA1'   => 0,
        'Scalar::Util'   => 0,
        'XML::Feed'      => 0,
        'Encode'         => 0,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX   => 'gz',
       PREOP => 'pod2text lib/AnyEvent/Feed.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'AnyEvent-Feed' },
);
