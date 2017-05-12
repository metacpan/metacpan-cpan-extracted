#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Data::Phrasebook::Loader::DBI',
    VERSION_FROM        => 'lib/Data/Phrasebook/Loader/DBI.pm',
    ABSTRACT            => 'Loader class for phrasebook implementations using DBI',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Carp'                  => '0',
        'Data::Phrasebook'      => '0.24',
        'DBI'                   => '1.38',

        # build/test prereqs
        'Test::More'            => '0.70',
        'IO::File'              => '0'

    }
);
