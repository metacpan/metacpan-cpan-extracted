use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Auth::Extensible::Provider::Usergroup',
    AUTHOR           => q{Henk van Oers <hvo.pm@xs4all.nl>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/Usergroup.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Auth/Extensible/Provider/Usergroup.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION => 5.010001,
    PL_FILES         => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer2'    => '0.200000',
        'Dancer2::Plugin::Auth::Extensible' => '0.620',
        'Dancer2::Plugin::DBIC' => '0.0012',
        'Dancer2::Plugin::Passphrase' => 3.000002,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Auth-Extensible-Provider-Usergroup-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/hvoers/Dancer2-Plugin-Auth-Extensible-Provider-Usergroup',
            bugtracker => 'https://github.com/hvoers/Dancer2-Plugin-Auth-Extensible-Provider-Usergroup/issues',
            homepage   => 'https://github.com/hvoers/Dancer2-Plugin-Auth-Extensible-Provider-Usergroup/',
        },
    },
);
