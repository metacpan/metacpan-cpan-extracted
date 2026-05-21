use v5.40.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'App::pod2gfm',
    AUTHOR           => q{ryoskzypu <ryoskzypu@proton.me>},
    VERSION_FROM     => 'lib/App/pod2gfm.pm',
    ABSTRACT_FROM    => 'lib/App/pod2gfm.pm',
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => 'v5.40.0',
    EXE_FILES        => [
        'bin/pod2gfm',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Capture::Tiny'         => '0.50',
        'File::Spec'            => '0',
        'File::Spec::Functions' => '0',
        'Path::Tiny'            => '0.150',
        'Test2::V1'             => '0',

    },
    PREREQ_PM => {
        'File::Basename'           => '0',
        'File::Spec'               => '0',
        'Object::Pad'              => '0.825',
        'Pod::Markdown::Githubert' => '0.05',
        'Pod::Usage'               => '0',
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
            runtime => {
                recommends => {
                    'Getopt::Long::More' => '0.007',
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ryoskzypu/App-pod2gfm.git',
                web  => 'https://github.com/ryoskzypu/App-pod2gfm',
            },
            bugtracker => {
                web => 'https://github.com/ryoskzypu/App-pod2gfm/issues',
            },
        },
        x_contributors => [
            q{ryoskzypu <ryoskzypu@proton.me>},
        ],
        x_spdx_expression => 'MIT-0',
    },
);

WriteMakefile(%WriteMakefileArgs);
