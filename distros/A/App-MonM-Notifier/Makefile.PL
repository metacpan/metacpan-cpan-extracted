#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'App::MonM'             => 1.06,
        'Class::C3::Adopt::NEXT'=> 0.13,
        'Compress::Raw::Zlib'   => 0,
        'CTK'                   => 2.01,
        'DBI'                   => 1.60,
        'DBD::SQLite'           => 1.40,
        'Email::MIME'           => 1.90, # libemail-mime-perl
        'Email::Sender'         => 1.30, # libemail-sender-perl
        'File::Copy'            => 2.18,
        'File::Find'            => 1.15,
        'File::HomeDir'         => 1.00,
        'Text::SimpleTable'     => 2.03,
        'Time::Local'           => 0,
        'Try::Tiny'             => 0.07,
    };


my $exefiles = [qw(
        bin/monotifier
    )];

WriteMakefile(
    'NAME'              => 'App::MonM::Notifier',
    'MIN_PERL_VERSION'  => 5.016001,
    'VERSION_FROM'      => 'lib/App/MonM/Notifier.pm',
    'ABSTRACT_FROM'     => 'lib/App/MonM/Notifier.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'EXE_FILES'         => $exefiles,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        resources => {
            homepage        => 'https://sourceforge.net/projects/app-monm-notifier/',
            repository      => 'https://svn.code.sf.net/p/app-monm-notifier/code/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
);

1;
