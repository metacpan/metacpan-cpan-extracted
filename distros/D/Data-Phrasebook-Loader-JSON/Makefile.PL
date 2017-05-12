#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Data::Phrasebook::Loader::JSON',
    VERSION_FROM        => 'lib/Data/Phrasebook/Loader/JSON.pm',
    ABSTRACT            => 'Loader class for phrasebook implementations using JSON files',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Carp'                  => '0',
        'Data::Phrasebook'      => '0.24',
        'File::Slurp'           => '0',
        'JSON::XS'              => '0',

        # build/test prereqs
        'Test::More'            => '0.70',
        'IO::File'              => '0'

    }
);
