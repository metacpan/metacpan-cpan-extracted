#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Data::FormValidator::Constraints::Words',
    VERSION_FROM        => 'lib/Data/FormValidator/Constraints/Words.pm',
    ABSTRACT            => 'A contraints module of word patterns for Data::FormValidator',
    NO_META             => 1,
    PREREQ_PM => {

        'Data::FormValidator'   => '4.00',

        # for testing
        'IO::File'              => '0',
        'Test::More'            => '0.70'

    }
);
