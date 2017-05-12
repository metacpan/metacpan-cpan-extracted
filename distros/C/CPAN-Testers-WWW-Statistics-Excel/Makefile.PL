#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::WWW::Statistics::Excel',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Statistics/Excel.pm',
    ABSTRACT            => 'Scripts to create the cpanstats website',
    NO_META             => 1,
    PREREQ_PM => {

        # for module
        'Class::Accessor::Fast'     => 0,
        'File::Basename'            => 0,
        'File::Path'                => 0,
        'HTML::Entities'            => 0,
        'HTML::TokeParser'          => 0,
        'IO::File'                  => 0,
        'Spreadsheet::WriteExcel'   => 0,

        # for scripts
        'Getopt::ArgvFile'          => 0,
        'Getopt::Long'              => 0,

        # for testing
        'File::Slurp'               => 0,
        'Test::More'                => 0.70

    },
);
