#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Data::Dumper::Store',
    AUTHOR              => q{shootnix <shootnix@cpan.org>},
    VERSION_FROM        => 'lib/Data/Dumper/Store.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Data::Dumper' => '0',
    },
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/shootnix/data-dumper-store',
        },
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data::Dumper::Store-*' },
)
