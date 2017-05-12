#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::Data::Uploads',
    VERSION_FROM        => 'lib/CPAN/Testers/Data/Uploads.pm',
    ABSTRACT            => 'CPAN Testers Uploads Database Generator',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Class::Accessor::Fast'             => '0',
        'CPAN::DistnameInfo'                => '0.10',
        'CPAN::Testers::Common::Article'    => '0',
        'CPAN::Testers::Common::DBUtils'    => '0.08',
        'Config::IniFiles'                  => '0',
        'DBI'                               => '0',
        'File::Basename'                    => '0',
        'File::Find::Rule'                  => '0',
        'File::Path'                        => '0',
        'File::Slurp'                       => '0',
        'Getopt::Long'                      => '0',
        'IO::AtomicFile'                    => '0',
        'IO::File'                          => '0',
        'Net::NNTP'                         => '0',

        'DBD::mysql'                        => '0',
        'DBD::SQLite'                       => '0',

        # build/test prereqs
        'Archive::Extract'                  => '0',
        'Archive::Zip'                      => '0',
        'Test::More'                        => '0.70',
        'Test::Trap'                        => '0',

    }
);
