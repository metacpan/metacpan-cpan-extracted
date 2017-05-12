use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Plugin::Auth::Extensible::Provider::Usergroup',
    AUTHOR           => q{Henk van Oers <hvo.pm@xs4all.nl>},
    VERSION_FROM     => 'lib/Dancer/Plugin/Auth/Extensible/Provider/Usergroup.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/Auth/Extensible/Provider/Usergroup.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES         => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 1.3118,
        'Dancer::Plugin::Auth::Extensible' => 0,
        'Dancer::Plugin::DBIC' => 0,
        'Dancer::Plugin::Passphrase' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-Auth-Extensible-Provider-Usergroup-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/hvoers/Dancer-Plugin-Auth-Extensible-Provider-Usergroup',
            bugtracker => 'https://github.com/hvoers/Dancer-Plugin-Auth-Extensible-Provider-Usergroup/issues',
            homepage   => 'https://github.com/hvoers/Dancer-Plugin-Auth-Extensible-Provider-Usergroup/',
        },
    },
);
