use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::TimelogTxt',
    AUTHOR              => 'G. Wade Johnson <gwadej@cpan.org>',
    VERSION_FROM        => 'lib/App/TimelogTxt.pm',
    ABSTRACT_FROM       => 'lib/App/TimelogTxt.pm',
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => 5.010,
    EXE_FILES           => [ 'bin/timelog' ],
    PL_FILES            => {},
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Most'       => 0,
        'Test::NoWarnings' => 0,
    },
    PREREQ_PM => {
        'POSIX'            => 0,
        'File::Path'       => 0,
        'Time::Local'      => 0,
        'Getopt::Long'     => 0,
        'Config::Tiny'     => 0,
        'autodie'          => 0,
        'App::CmdDispatch' => 0.42,
        'List::Util'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-TimelogTxt-*' },
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gwadej/app-timelogtxt.git',
                web  => 'https://github.com/gwadej/timelogtxt',
            },
        },
    },
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);
