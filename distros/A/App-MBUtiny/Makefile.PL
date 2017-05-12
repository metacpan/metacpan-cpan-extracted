#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Class::C3::Adopt::NEXT'=> 0.13,
        'CTK'                   => 1.16,
        'DBI'                   => 1.60,
        'Digest::MD5'           => 2.51,
        'Digest::SHA1'          => 2.13,
        'File::Copy'            => 2.18,
        'File::Find'            => 1.15,
        'File::Path'            => 2.00,
        'HTTP::Headers'         => 5.80,
        'HTTP::Request'         => 5.80,
        'HTTP::Response'        => 5.80,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::UserAgent'        => 5.80,
        'Socket'                => 0,
        'Text::SimpleTable'     => 2.03,
        'Text::Unidecode'       => 0.04,
        'Try::Tiny'             => 0.07,
        'WWW::MLite'            => 1.05,
        'URI'                   => 1.50,
        'XML::Simple'           => 2.20,
    };
my $exefiles = [qw[
        bin/mbutiny
    ]];

WriteMakefile(
    'NAME'                  => 'App::MBUtiny',
    'DISTNAME'              => 'App-MBUtiny',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/App/MBUtiny.pm', 
    'ABSTRACT_FROM'         => 'lib/App/MBUtiny.pm', ,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'gpl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://app-mbutiny.sourceforge.net',
            repository      => 'https://svn.code.sf.net/p/app-mbutiny/code/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
);

1;
