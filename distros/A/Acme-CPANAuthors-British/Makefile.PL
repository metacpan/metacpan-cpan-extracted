#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Acme::CPANAuthors::British',
    VERSION_FROM        => 'lib/Acme/CPANAuthors/British.pm',
    ABSTRACT            => 'We are British CPAN authors',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Acme::CPANAuthors' => '0.04',

        # build/test prereqs
        'Test::More'        => '0.70',
        'IO::File'          => '0'

    },

    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-CPANAuthors-British-*' }
);
