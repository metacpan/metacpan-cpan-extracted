# Makefile.PL for building the Acme::DonMartin module
#
# Copyright (c) David Landgren

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Acme::DonMartin',
    VERSION_FROM  => 'DonMartin.pm',
    ABSTRACT_FROM => 'DonMartin.pm',
    AUTHOR        => 'David Landgren',
    LICENSE       => 'perl',
    PREREQ_PM => {
        'Compress::Zlib' => 0,
    },
);
