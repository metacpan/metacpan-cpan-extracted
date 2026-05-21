use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::PerlGlue',
    VERSION_FROM  => 'lib/App/PerlGlue.pm',
    ABSTRACT_FROM => 'lib/App/PerlGlue.pm',
    AUTHOR        => 'Shingo Kawamura <pannakoota1@gmail.com>',
    LICENSE       => 'perl_5',
    EXE_FILES     => ['bin/perlglue'],
    PREREQ_PM     => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/kawamurashingo/App-PerlGlue.git',
                web  => 'https://github.com/kawamurashingo/App-PerlGlue',
            },
        },
    },
);
