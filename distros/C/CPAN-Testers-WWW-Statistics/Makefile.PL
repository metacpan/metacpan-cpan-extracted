#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

die "OS unsupported" if( $^O eq 'MSWin32' );

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN-Testers-WWW-Statistics',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Statistics.pm',
    ABSTRACT            => 'Scripts to create the CPAN Testers Statistics website',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Class::Accessor::Fast'             => 0,
        'Config::IniFiles'                  => 0,
        'Data::Dumper'                      => 0,       # for debugging purposes
        'DateTime'                          => 0,
        'GD::Graph::lines'                  => 0,
        'File::Basename'                    => 0,
        'File::Copy'                        => 0,
        'File::Path'                        => 0,
        'File::Slurp'                       => 0,
        'Getopt::ArgvFile'                  => 0,
        'Getopt::Long'                      => 0,
        'HTML::Entities'                    => 0,
        'HTTP::Request'                     => 0,
        'IO::File'                          => 0,
        'JSON'                              => 0,
        'LWP::UserAgent'                    => 0,
        'Regexp::Assemble'                  => 0,
        'Sort::Versions'                    => 0,
        'Template'                          => 2.19,
        'Time::Piece'                       => 0,

        # for getmailrc.pl
        'WWW::Mechanize'                    => 0,

        # for cgimail.pl
        'CGI'                               => 0,

        # for database access
        'CPAN::Testers::Common::DBUtils'    => 0.03,
        'DBI'                               => 0,
        'DBD::mysql'                        => 0,

        # for testing
        'Archive::Zip'                      => 0,       # for testing
        'Archive::Extract'                  => 0,       # for testing
        'Cwd'                               => 0,       # for testing
        'File::Spec'                        => 0,       # for testing
        'Test::Differences'                 => 0,       # for testing
        'Test::More'                        => 0.70     # for testing

    },
);
