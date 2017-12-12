#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Class::C3::Adopt::NEXT'=> 0.13,
        'CTK'                   => 1.18,
        'Data::Dumper'          => 0,
        'DateTime'              => 0,
        'DateTime::Format::W3CDTF' => 0,
        'DBI'                   => 1.60,
        'DBD::SQLite'           => 1.40,
        'Email::MIME'           => 1.90, # libemail-mime-perl
        'Email::Sender'         => 1.30, # libemail-sender-perl
        'File::Copy'            => 2.18,
        'File::Find'            => 1.15,
        'File::Path'            => 2.00,
        'HTTP::Cookies'         => 6.00,
        'HTTP::Message'         => 6.02,
        'IO::String'            => 1.08,
        'JSON'                  => 2.53,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::UserAgent'        => 5.80,
        'MRO::Compat'           => 0.13,
        'Net::SSLeay'           => 1.52,
        'Text::SimpleTable'     => 2.03,
        'Try::Tiny'             => 0.07,
        'URI'                   => 1.50,
    };

my $exefiles = [qw(
        bin/monotifier
        bin/monotifierd
    )];

WriteMakefile(
    'NAME'              => 'App::MonM::Notifier',
    'MIN_PERL_VERSION'  => 5.012001,
    'VERSION_FROM'      => 'lib/App/MonM/Notifier.pm',
    'ABSTRACT_FROM'     => 'lib/App/MonM/Notifier.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'EXE_FILES'         => $exefiles,
    'AUTHOR'            => 'Sergey Lepenkov (Serz Minus) http://www.serzik.com <abalama@cpan.org>',
    'LICENSE'           => 'GPL',
    'META_MERGE'        => {
        resources => {
            homepage        => 'http://www.serzik.com',
            repository      => 'https://svn.code.sf.net/p/app-monm-notifier/code/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
    macro => {
            # Main constants
            PROJECTNAME => 'monotifier',
            PROJECTNAMEL => 'monotifier',
            PROJECTNAMEUCF => 'Monotifier',
        },
    clean => {
            FILES => 'ChangeLog',
        },
);

eval {
  require File::Copy;
  File::Copy::cp("CHANGES", "ChangeLog");
};

1;
