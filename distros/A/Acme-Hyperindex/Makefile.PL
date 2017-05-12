#!/usr/bin/perl

use 5.6.0;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Acme::Hyperindex',
    VERSION_FROM    => 'lib/Acme/Hyperindex.pm',
    ABSTRACT_FROM   => 'lib/Acme/Hyperindex.pm',
    PREREQ_PM       => {
        'Test::More'        => 0,
        'Carp'              => 0,
        'Filter::Simple'    => 0,
    },
    AUTHOR          => 'Berik Visschers',
);



