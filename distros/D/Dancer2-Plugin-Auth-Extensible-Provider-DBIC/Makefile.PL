use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer2::Plugin::Auth::Extensible::Provider::DBIC',
    AUTHOR              => q{Andy Beverley <andy@andybev.com>},
    VERSION_FROM        => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/DBIC.pm',
    ABSTRACT_FROM       => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/DBIC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    BUILD_REQUIRES => {
        'Test::MockObject' => 0,
        'Test::More'  => 0,
        'Test::Warn'  => 0,
        'DateTime::Format::SQLite' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Dancer2' => '0.200000',
        'Dancer2::Core::Types' => 0,
        'Dancer2::Plugin::DBIC' => '0.0012',
        'Dancer2::Plugin::Auth::Extensible' => '0.708',
        'DateTime' => 0,
        'DBIx::Class::ResultClass::HashRefInflator' => 0,
        'Scalar::Util' => 0,
        'String::CamelCase' => 0,
        'Moo' => 0,
        'namespace::clean' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer2-Plugin-Auth-Extensible-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/ctrlo/Dancer2-Plugin-Auth-Extensible-Provider-DBIC',
            bugtracker => 'https://github.com/ctrlo/Dancer2-Plugin-Auth-Extensible-Provider-DBIC/issues',
            homepage   => 'https://github.com/ctrlo/Dancer2-Plugin-Auth-Extensible-Provider-DBIC/',
            IRC        => 'irc://irc.perl.org/#dancer',
        },
    },

);
