#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Class::C3::Adopt::NEXT'=> 0,
        'CGI',                  => 4.36,
        'CTK'                   => 2.01,
        'DBI'                   => 1.60,
        'DBD::SQLite'           => 1.50,
        'Digest::MD5'           => 2.51,
        'Digest::SHA1'          => 2.13,
        'File::Copy'            => 2.18,
        'File::Find'            => 1.15,
        'File::Path'            => 2.00,
        'HTTP::Message'         => 5.00,
        'List::Util'            => 1.45,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'Net::FTP'              => 2.60,
        'Net::SFTP::Foreign'    => 1.90,
        'Socket'                => 0,
        'Sys::Hostname'         => 0,
        'Text::SimpleTable'     => 2.03,
        'WWW::MLite'            => 2.01,
        'URI'                   => 1.71,
    };
my $exefiles = [qw[
        bin/mbutiny
    ]];

WriteMakefile(
    'NAME'                  => 'App::MBUtiny',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/App/MBUtiny.pm',
    'ABSTRACT_FROM'         => 'lib/App/MBUtiny.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'               => 'perl',
    'META_MERGE' => { 'meta-spec' => { version => 2 },
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://app-mbutiny.sourceforge.net',
            repository      => 'https://svn.code.sf.net/p/app-mbutiny/code/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
    clean => {
        FILES => '*.db *.tmp',
    },

);
