use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Auth::Extensible::Provider::ActiveDirectory',
    AUTHOR           => q{Dominic Sonntag <dominic@s5g.de>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/ActiveDirectory.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/ActiveDirectory.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Net::LDAP' => 0,
    },
    PREREQ_PM => {
        'Carp'                              => 0,
        'Dancer2::Core::Types'              => 0,
        'Dancer2::Plugin::Auth::Extensible' => '0.620',
        'Moo'                               => '2.000000',
        'namespace::clean'                  => 0,
        'Auth::ActiveDirectory'             => 0,
        'YAML' => 0,    # for config files and tests
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/sonntagd/Dancer2-Plugin-Auth-Extensible-Provider-ActiveDirectory.git',
                web  => 'https://github.com/sonntagd/Dancer2-Plugin-Auth-Extensible-Provider-ActiveDirectory',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Auth-Extensible-Provider-ActiveDirectory-*' },
);
