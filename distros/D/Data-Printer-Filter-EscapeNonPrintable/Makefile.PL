use v5.26.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Data::Printer::Filter::EscapeNonPrintable',
    AUTHOR             => q{ryoskzypu <ryoskzypu@proton.me>},
    VERSION_FROM       => 'lib/Data/Printer/Filter/EscapeNonPrintable.pm',
    ABSTRACT_FROM      => 'lib/Data/Printer/Filter/EscapeNonPrintable.pm',
    LICENSE            => 'open_source',
    MIN_PERL_VERSION   => 'v5.26.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Data::Printer::Filter' => '0',
        'Data::Printer::Object' => '0',
        'Test2::V1'             => '0',
    },
    PREREQ_PM => {
        'Data::Printer'         => '1.000000',
        'Data::Printer::Filter' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => {
            directory => [
                qw<
                    eg
                    examples
                    share
                    xt
                >
            ],
        },
        prereqs => {
            develop => {
                recommends => {
                    'App::CPANTS::Lint' => '0',
                    'Data::Printer'     => '0',
                    'Devel::Cover'      => '0',
                    'Devel::NYTProf'    => '0',
                    'Perl::Critic'      => '0',
                    'Perl::Tidy'        => '0',
                },
                requires => {
                    'Test::CPAN::Changes' => '0',
                    'Test::Kwalitee'      => '0',
                    'Test::Perl::Critic'  => '0',
                    'Test::Pod'           => '0',
                    'Test::Pod::Coverage' => '0',
                    'Test::Spelling'      => '0',
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ryoskzypu/Data-Printer-Filter-EscapeNonPrintable.git',
                web  => 'https://github.com/ryoskzypu/Data-Printer-Filter-EscapeNonPrintable',
            },
            bugtracker => {
                web => 'https://github.com/ryoskzypu/Data-Printer-Filter-EscapeNonPrintable/issues',
            },
        },
        x_contributors => [
            q{ryoskzypu <ryoskzypu@proton.me>},
        ],
        x_spdx_expression => 'MIT-0',
    },
);

WriteMakefile(%WriteMakefileArgs);
