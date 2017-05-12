#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Acme::CPANAuthors::InMemoriam',
    VERSION_FROM        => 'lib/Acme/CPANAuthors/InMemoriam.pm',
    ABSTRACT            => 'In honour of our deceased CPAN Authors',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Acme::CPANAuthors' => '0.04',

        # build/test prereqs
        'IO::File'          => '0',
        'Test::More'        => '0.70'

    },

    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-CPANAuthors-InMemoriam-*' }
);
