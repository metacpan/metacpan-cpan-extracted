use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Const::Dual',
    AUTHOR           => 'Sergey Panteleev <bambr@cpan.org>',
    VERSION_FROM     => 'lib/Const/Dual.pm',
    ABSTRACT_FROM    => 'lib/Const/Dual.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist              => {
       PREOP          => 'pod2text lib/Const/Dual.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS       => 'gzip -9v',
       SUFFIX         => '.gz',
    },
);
