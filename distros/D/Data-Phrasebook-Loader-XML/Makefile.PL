#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Data::Phrasebook::Loader::XML',
    VERSION_FROM        => 'lib/Data/Phrasebook/Loader/XML.pm',
    ABSTRACT            => 'Loader class for phrasebook implementations using XML files',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Carp'                  => '0',
        'Data::Phrasebook'      => '0.24',
        'IO::File'              => '0',
        'XML::Parser'           => '0',

        # build/test prereqs
        'Test::More'            => '0.70',

    }
);
