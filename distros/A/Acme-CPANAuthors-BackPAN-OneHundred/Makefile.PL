#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Acme-CPANAuthors-BackPAN-OneHundred',
    VERSION_FROM        => 'lib/Acme/CPANAuthors/BackPAN/OneHundred.pm',
    ABSTRACT            => 'The CPAN Authors who currently have 100 or more distributions on CPAN',
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
    clean               => { FILES => 'Acme-CPANAuthors-BackPAN-OneHundred-*' }
);
