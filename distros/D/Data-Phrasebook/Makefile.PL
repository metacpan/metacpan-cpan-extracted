#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Data::Phrasebook',
    VERSION_FROM        => 'lib/Data/Phrasebook.pm',
    ABSTRACT            => 'Access your data using the phrasebook design pattern',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Carp'                  => '0',
        'IO::File'              => '0',
        'Module::Pluggable'     => '2.7',

        # build/test prereqs
        'Test::More'            => '0.70',

    }
);
