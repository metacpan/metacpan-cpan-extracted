#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Mini::Tested',
    VERSION_FROM        => 'lib/CPAN/Mini/Tested.pm',
    ABSTRACT            => 'Create a CPAN mirror using modules with passing test reports',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'base'                          => '0',
        'Cache::Simple::TimedExpiry'    => '0.22',
        'CPAN::Mini'                    => '0.32',
        'Config'                        => '0',
        'DBD::SQLite'                   => '1',
        'DBI'                           => '0',
        'File::Basename'                => '0',
        'File::Spec::Functions'         => '0',
        'LWP::Simple'                   => '0',
        'Regexp::Assemble'              => '0.06',

        # build/test prereqs
        'IO::File'                      => '0',
        'Test::More'                    => '0.70'

    }
);
