#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::WWW::Development',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Development.pm',
    ABSTRACT            => 'The CPAN Testers Development website',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Config::IniFiles'  => 0,
        'File::Basename'    => 0,
        'File::Copy'        => 0,
        'File::Path'        => 0,
        'Getopt::ArgvFile'  => 0,
        'Getopt::Long'      => 0,
        'Number::Format'    => 0,
        'Template'          => 0,

        # for testing
        'IO::File'          => 0,       # for testing
        'Test::More'        => 0.70     # for testing

    },
);
