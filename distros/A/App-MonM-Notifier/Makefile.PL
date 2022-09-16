#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'App::MonM'             => 1.09,
        'CTK'                   => 2.09, # libctk-perl
        'DBI'                   => 1.60, # libdbi-perl
        'DBD::SQLite'           => 1.40, # libdbd-sqlite3-perl
        'Text::SimpleTable'     => 2.03, # libtext-simpletable-perl
        'MIME::Base64'          => 3.00, # libemail-mime-encodings-perl
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
    clean => {
        FILES => '*.db',
    },
);

1;
