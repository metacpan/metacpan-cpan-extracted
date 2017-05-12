#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN-Testers-Data-Generator',
    VERSION_FROM        => 'lib/CPAN/Testers/Data/Generator.pm',
    ABSTRACT            => 'CPAN Testers cpanstats Database Generator',
    NO_META             => 1,

    PREREQ_PM           => {

        # prereqs
        'Config::IniFiles'                  => 0,
        'CPAN::Testers::Common::Article'    => 0.36,
        'CPAN::Testers::Common::DBUtils'    => 0.03,
        'CPAN::Testers::Fact::LegacyReport' => 1.999001,
        'CPAN::Testers::Fact::TestSummary'  => 1.999001,
        'CPAN::Testers::Metabase::AWS'      => 1.999002,
        'CPAN::Testers::Report'             => 1.999001,
        'Data::FlexSerializer'              => 0,
        'DateTime'                          => 0,
        'DateTime::Duration'                => 0,
        'File::Basename'                    => 0,
        'File::Path'                        => 0,
        'File::Slurp'                       => 0,
        'HTML::Entities'                    => 0,
        'IO::File'                          => 0,
        'JSON'                              => 0,
        'Metabase'                          => 1.003,
        'Metabase::Fact'                    => 0.023,
        'Metabase::Resource'                => 0.023,
        'Sereal'                            => 0,
        'Time::Local'                       => 0,

        'DBI'                               => 0,
        'DBD::mysql'                        => 0,
        'DBD::SQLite'                       => 1.07,

        # used by run scripts
        'Getopt::Long'                      => 0,
        'Getopt::ArgvFile'                  => 0,

        # build/test prereqs
        'Test::More'                        => '0.70'

    },

    EXE_FILES           => [ 'bin/cpanstats' ]
);
