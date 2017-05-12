use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::CmdDispatch',
    AUTHOR              => 'G. Wade Johnson <gwadej@cpan.org>',
    VERSION_FROM        => 'lib/App/CmdDispatch.pm',
    ABSTRACT_FROM       => 'lib/App/CmdDispatch.pm',
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => 5.006,
    EXE_FILES           => [],
    PL_FILES            => {},
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::Exception' => 0,
        'Config::Tiny' => 0,
        'Term::ReadLine' => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean              => { FILES => 'App-CmdDispatch-*' },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gwadej/app-cmddispatch.git',
                web  => 'https://github.com/gwadej/app-cmddispatch',
            },
        },
    },
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);
