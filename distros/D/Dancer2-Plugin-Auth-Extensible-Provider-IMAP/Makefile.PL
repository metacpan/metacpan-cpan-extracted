use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Auth::Extensible::Provider::IMAP',
    AUTHOR           => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/IMAP.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/IMAP.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'                              => 0,
        'Dancer2::Core::Types'              => 0,
        'Dancer2::Plugin::Auth::Extensible' => '0.620',
        'IO::Socket::SSL'                   => 0,
        'Moo'                               => '2.000000',
        'namespace::clean'                  => 0,
        'Net::IMAP::Simple'                 => '1.2207',
        'YAML' => 0,    # for config files and tests
      },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Auth-Extensible-Provider-IMAP-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-IMAP',
            bugtracker => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-IMAP/issues',
            homepage   => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-IMAP/',
            IRC        => 'irc://irc.perl.org/#dancer',
        },
    },
);
