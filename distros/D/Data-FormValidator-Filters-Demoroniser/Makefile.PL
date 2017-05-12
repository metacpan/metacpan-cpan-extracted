#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Data::FormValidator::Filters::Demoroniser',
    VERSION_FROM        => 'lib/Data/FormValidator/Filters/Demoroniser.pm',
    ABSTRACT            => 'A Data::FormValidator filter that allows you to demoronise a string',
    NO_META             => 1,
    PREREQ_PM => {

        # for module
        'Text::Demoroniser'     => 0,

        # for testing
        'IO::File'              => 0,
        'Test::More'            => 0.70

    }
);
