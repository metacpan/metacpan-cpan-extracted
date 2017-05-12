use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer2::Plugin::Auth::Extensible::Provider::LDAP',
    AUTHOR              => q{Peter Mottram <peter@sysnix.com>},
    VERSION_FROM        => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/LDAP.pm',
    ABSTRACT_FROM       => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/LDAP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('MIN_PERL_VERSION'=> '5.6.0')
      : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Net::LDAP' => '0.07',
    },
    PREREQ_PM => {
        'Carp'                              => 0,
        'Dancer2::Core::Types'              => 0,
        'Dancer2::Plugin::Auth::Extensible' => '0.620',
        'Moo'                               => '2.000000',
        'namespace::clean'                  => 0,
        'Net::LDAP'                         => 0,
        'YAML' => 0,    # for config files and tests
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Auth-Extensible-Provider-LDAP*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-LDAP',
            bugtracker => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-LDAP/issues',
            homepage   => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible-Provider-LDAP/',
            IRC        => 'irc://irc.perl.org/#dancer',
        },
    },
);
