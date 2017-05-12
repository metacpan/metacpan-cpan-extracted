use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Class::DeploymentHandler::CLI',
    AUTHOR           => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM     => 'lib/DBIx/Class/DeploymentHandler/CLI.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Class/DeploymentHandler/CLI.pm',
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
        'Moo' => 2,
        'Type::Tiny' => '0.038',
        'DBIx::Class::DeploymentHandler' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Class-DeploymentHandler-CLI-*' },

    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/DBIx-Class-DeploymentHandler-CLI.git',
            bugtracker => 'https://github.com/interchange/DBIx-Class-DeploymentHandler-CLI/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
