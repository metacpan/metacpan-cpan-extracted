#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

print <<HERE;

  Please note that the tests within this distribution can take a long time
  to run. As such, be prepared to wait a little while to get the results.

HERE

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::WWW::Reports::Mailer',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Reports/Mailer.pm',
    ABSTRACT            => 'CPAN Testers Reports Mailer',
    NO_META             => 1,

    PREREQ_PM           => {

        # prereqs
        'Compress::Zlib'                    => 0,
        'Config::IniFiles'                  => 0,
        'Class::Accessor::Fast'             => 0,
        'CPAN::Testers::Common::DBUtils'    => 0.03,
        'CPAN::Testers::Common::Utils'      => 0,
        'CPAN::Testers::Fact::LegacyReport' => 0,
        'CPAN::Testers::Fact::TestSummary'  => 0,
        'Data::Dumper'                      => 0,
        'Data::FlexSerializer'              => 0,
        'Email::Address'                    => 0,
        'Email::Simple'                     => 0,
        'File::Basename'                    => 0,
        'File::Path'                        => 0,
        'File::Slurp'                       => 0,
        'Getopt::ArgvFile'                  => 0,
        'Getopt::Long'                      => 0,
        'IO::File'                          => 0,
        'JSON'                              => 0,
        'LWP::UserAgent'                    => 0,
        'Math::Random::MT'                  => 0,
        'Metabase::Resource'                => 0,
        'MIME::Base64'                      => 0,
        'MIME::QuotedPrint'                 => 0,
        'Path::Class'                       => 0,
        'Parse::CPAN::Authors'              => 0,
        'Template'                          => 0,
        'Time::Piece'                       => 0,
        'version'                           => 0,
        'WWW::Mechanize'                    => 0,

        'DBI'                               => 0,
        'DBD::mysql'                        => 0,
        'DBD::SQLite'                       => '1.07',

        # build/test prereqs
        'Test::More'                        => '0.70',
        'Test::Trap'                        => '0'

    },

    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/cpanreps-mailer' ],
);
