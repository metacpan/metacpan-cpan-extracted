use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::LedgerSMB::Admin',
    AUTHOR           => q{Chris Travers <chris@efficito.com>},
    VERSION_FROM     => 'lib/App/LedgerSMB/Admin.pm',
    ABSTRACT_FROM    => 'lib/App/LedgerSMB/Admin.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    EXE_FILES        => [ 'bin/lsmb_reload', 'bin/lsmb_createdb' ],
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        "Test::Exception" => 0,
    },
    PREREQ_PM => {
        "Moo"                      => 0,
        "PGObject::Simple::Role"   => 0,
        "PGObject::Util::DBMethod" => 0,
        "PGObject::Util::DBAdmin"  => 0,
        "PGObject::Util::DBChange"  => 0.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-LedgerSMB-Admin-*' },
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           repository => {
             type => 'git',
             url  => 'https://github.com/ledgersmb/App-LedgerSMB-Admin.git',
             web  => 'https://github.com/ledgersmb/App-LedgerSMB-Admin',
           },
       },
    },
);
