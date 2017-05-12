#!/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBD::Cassandra',
    AUTHOR           => q{Tom van der Woerdt <tvdw@cpan.org>},
    VERSION_FROM     => 'lib/DBD/Cassandra.pm',
    ABSTRACT_FROM    => 'lib/DBD/Cassandra.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'DBI'                    => '1.621',
        'Cassandra::Client'      => '0.10',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBD-Cassandra-*' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/tvdw/perl-DBD-Cassandra.git',
                web => 'https://github.com/tvdw/perl-DBD-Cassandra',
            }
        }
    },
);
