use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::Authen::LDAP',
    AUTHOR              => 'Edward Rudd <urkle@outoforder.cc>',
    VERSION_FROM        => 'lib/DJabberd/Authen/LDAP.pm',
    ABSTRACT_FROM       => 'lib/DJabberd/Authen/LDAP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => 0.83,
        'Net::LDAP' => 0.34
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DJabberd-Authen-LDAP-*' },
);
