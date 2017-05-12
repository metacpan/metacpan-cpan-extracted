use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::Plugin::VCard::LDAP',
    AUTHOR              => 'Edward Rudd <urkle@outoforder.cc>',
    VERSION_FROM        => 'lib/DJabberd/Plugin/VCard/LDAP.pm',
    ABSTRACT_FROM       => 'lib/DJabberd/Plugin/VCard/LDAP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => '0.83',
        'DJabberd::Plugin::VCard' => 0,
        'Net::LDAP' => 0,
    },
    DISTNAME		=> 'DJabberd-VCard-LDAP',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
