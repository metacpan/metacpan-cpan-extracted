#! perl
use v5.18;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME             => 'Data::Printer::Theme::Zellner',
    VERSION_FROM     => 'lib/Data/Printer/Theme/Zellner.pm',
    ABSTRACT_FROM    => 'lib/Data/Printer/Theme/Zellner.pm',
    AUTHOR           => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.18.0',

    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },
    TEST_REQUIRES => {
        'Test::Simple'     => 0.88,
        'Test::Warnings'   => 0,
        'Test::Fatal'      => 0,
    },
    PREREQ_PM => {
        'Data::Printer' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/abeltje/Data-Printer-Theme-Zellner.git',
                web => 'https://github.com/abeltje/Data-Printer-Theme-Zellner.git',
            },
            bugtracker => {
                web => 'https://github.com/abeltje/Data-Printer-Theme-Zellner/issues',
            },
        },
    }
);
