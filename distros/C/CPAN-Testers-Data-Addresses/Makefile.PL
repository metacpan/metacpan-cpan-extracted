#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::Data::Addresses',
    VERSION_FROM        => 'lib/CPAN/Testers/Data/Addresses.pm',
    ABSTRACT            => 'CPAN Testers Addresses Database Manager',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Class::Accessor::Fast'             => 0,
        'CPAN::Testers::Common::DBUtils'    => '0.08',
        'Config::IniFiles'                  => 0,
        'File::Basename'                    => 0,
        'File::Path'                        => 0,
        'File::Slurp'                       => 0,
        'Getopt::Long'                      => 0,
        'IO::File'                          => 0,

        # indirect runtime prereqs
        'DBI'                               => 0,
        'DBD::mysql'                        => 0,
        'DBD::SQLite'                       => 0,

        # build/test prereqs
        'Test::More'                        => '0.70',

    }
);
