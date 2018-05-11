use 5.010;
use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::NDTools',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/App/NDTools.pm',
    ABSTRACT_FROM    => 'lib/App/NDTools.pm',
    LICENSE          => 'gpl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'JSON::PP'              => 0, # required by YAML::XS
        'Storable'              => 0,
        'Test::File::Contents'  => 0.23,
        'Test::More'            => 0,
        'YAML::XS'              => 0, # optional (lazy loaded)
    },
    EXE_FILES => [
        'nddiff',
        'ndpatch',
        'ndproc',
        'ndquery',
    ],
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/NDTools',
        },
    },
    PREREQ_PM => {
        'Encode::Locale'            => 0,
        'Hash::Merge'               => 0,
        'Hash::Merge::Extra'        => 0.06,
        'IPC::Run3'                 => 0,
        'JSON'                      => 0,
        'Log::Log4Cli'              => 0.21,
        'Module::Find'              => 0,
        'Struct::Diff'              => 0.96,
        'Struct::Path'              => 0.81,
        'Struct::Path::PerlStyle'   => 0.80,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-NDTools-* cover_db' },
    test  => { TESTS => 't/*.t t/lib/*.t t/bin/*.t' },
);

