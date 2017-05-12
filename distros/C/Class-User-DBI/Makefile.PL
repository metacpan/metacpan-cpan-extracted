## no critic (RCS,VERSION,interpolation)
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Class::User::DBI',
    AUTHOR             => q{David Oswald <davido [@at] cpan [d.o.t] org>},
    VERSION_FROM       => 'lib/Class/User/DBI.pm',
    ABSTRACT_FROM      => 'lib/Class/User/DBI.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => '5.008000',
    PL_FILES           => {},
    EXE_FILES          => ['scripts/cudbi-configdb'],
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.62', },
    BUILD_REQUIRES     => {
        'Test::More'      => '0.98',
        'Test::Exception' => 0,
        'List::MoreUtils' => 0,
        'DBIx::Connector' => 0,
        'DBD::SQLite'     => 0,
    },
    PREREQ_PM => {
        'Authen::Passphrase::SaltedSHA512' => '0.06',
        'DBIx::Connector'                  => 0,
        'List::MoreUtils'                  => 0,
    },
    META_MERGE => {
        provides => {
            'Class::User::DBI' => {
                file    => 'lib/Class/User/DBI.pm',
                version => '0.10',
            },
            'Class::User::DBI::Roles' => {
                file    => 'lib/Class/User/DBI/Roles.pm',
                version => '0.10',
            },
            'Class::User::DBI::Privileges' => {
                file    => 'lib/Class/User/DBI/Privileges.pm',
                version => '0.10',
            },
            'Class::User::DBI::RolePrivileges' => {
                file    => 'lib/Class/User/DBI/RolePrivileges.pm',
                version => '0.10',
            },
            'Class::User::DBI::Domains' => {
                file    => 'lib/Class/User/DBI/Domains.pm',
                version => '0.10',
            },
            'Class::User::DBI::Userdomains' => {
                file    => 'lib/Class/User/DBI/UserDomains.pm',
                version => '0.10',
            },
        },
        version   => '0.10',
        resources => {
            repository => {
                web  => 'http://github.com/daoswald/Class-User-DBI.git',
                url  => 'git://github.com/daoswald/Class-User-DBI.git',
                type => 'git',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Class-User-DBI-*' },
);
