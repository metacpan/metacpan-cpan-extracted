use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Fast',
    AUTHOR           => q{Harun Delgado <hdp@nurmol.com>},
    VERSION_FROM     => 'lib/DBIx/Fast.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Fast.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
	'Test::More'      => 0,
	'Test::Exception' => 0.43,
	'DBD::SQLite'     => 1.50,
    },
    PREREQ_PM => {
	'Moo'             => 1,
	'SQL::Abstract'   => 2.00,
	'DBIx::Connector' => 0.53,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Fast-*' },
);
