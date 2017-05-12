use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::Authentication::Credential::JugemKey',
    AUTHOR              => 'Gosuke Miyashita <gosukenator@gmail.com>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/Authentication/Credential/JugemKey.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Plugin/Authentication/Credential/JugemKey.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Catalyst'   => 5.60,
        'WebService::JugemKey::Auth' => 0.03,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-Authentication-Credential-JugemKey-*' },
);
