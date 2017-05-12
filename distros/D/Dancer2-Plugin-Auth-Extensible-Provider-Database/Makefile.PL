use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Dancer2::Plugin::Auth::Extensible::Provider::Database',
    AUTHOR        => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM  => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/Database.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/Database.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Path::Tiny'                              => '0.016',
        'Test::More'                              => 0,
        'Dancer2::Plugin::Auth::Extensible::Test' => 0,
        'DBD::SQLite'                             => 0,
    },
    PREREQ_PM => {
        'Carp'                              => 0,
        'Dancer2'                           => '0.200000',
        'Dancer2::Plugin::Auth::Extensible' => '0.620',
        'Dancer2::Plugin::Database'         => '2.16',
        'Moo'                               => '2.000000',
        'namespace::clean'                  => 0,
        'YAML' => 0,    # for config files and tests
    },
    EXE_FILES => [],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Auth-Extensible-Provider-Database-*' },
    META_MERGE => {
        resources => {
            repository =>
'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-Database',
            bugtracker =>
'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-Database/issues',
            homepage =>
'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-Database/',
            IRC => 'irc://irc.perl.org/#dancer',
        },
    },

);
