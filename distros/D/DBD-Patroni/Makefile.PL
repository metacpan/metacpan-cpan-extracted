use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBD::Patroni',
    AUTHOR           => 'Xavier Guimard',
    VERSION_FROM     => 'lib/DBD/Patroni.pm',
    ABSTRACT_FROM    => 'lib/DBD/Patroni.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
    PREREQ_PM        => {
        'DBI'             => '1.614',
        'DBD::Pg'         => '3.0',
        'LWP::UserAgent'  => 0,
        'JSON'            => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/guimard/dbd-patroni.git',
                web  => 'https://github.com/guimard/dbd-patroni',
            },
            bugtracker => {
                web => 'https://github.com/guimard/dbd-patroni/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBD-Patroni-*' },
);
