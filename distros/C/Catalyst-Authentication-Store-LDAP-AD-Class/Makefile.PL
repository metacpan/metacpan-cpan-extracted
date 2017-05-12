use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Authentication::Store::LDAP::AD::Class',
    AUTHOR              => q{Andrey Chergik <andrey@chergik.ru>},
    VERSION_FROM        => 'lib/Catalyst/Authentication/Store/LDAP/AD/Class.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Authentication/Store/LDAP/AD/Class.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                        => 0,
        'Moose'                             => 0,
        'Class::Accessor::Fast'             => 0,
        'Net::LDAP'                         => 0,
        'Catalyst::Plugin::Authentication'  => '0.10003'
    },
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean    => { FILES => 'Catalyst-Authentication-Store-LDAP-AD-Class-*' },
);
