use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::GitKtti',
    AUTHOR              => 'saumon <shrekrobu@gmail.com>',
    VERSION_FROM        => 'lib/App/GitKtti.pm',
    ABSTRACT_FROM       => 'lib/App/GitKtti.pm',
    MIN_PERL_VERSION    => '5.014',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.98',
    },
    PREREQ_PM => {
        'POSIX'         => 0,
        'File::Basename' => 0,
        'Getopt::Long'  => 0,
        'strict'        => 0,
        'warnings'      => 0,
    },
    EXE_FILES => [
        'bin/gitktti-checkout',
        'bin/gitktti-delete',
        'bin/gitktti-fix',
        'bin/gitktti-fixend',
        'bin/gitktti-move',
        'bin/gitktti-tag',
        'bin/gitktti-tests',
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        license    => 'perl_5',
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/saumon/gitktti.git',
                web  => 'https://github.com/saumon/gitktti',
            },
            homepage => 'http://saumon.github.io/gitktti/',
            bugtracker => {
                web => 'https://github.com/saumon/gitktti/issues',
            },
        },
    },
    test => {
        TESTS => 't/*.t',
    },
    clean => {
        FILES => 'App-GitKtti-*',
    },
);
