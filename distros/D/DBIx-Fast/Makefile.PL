use 5.006;
use strict;
use warnings FATAL => 'all';
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
	'Test::More' => 0,
    },
    PREREQ_PM => {
	'DBIx::Connector' => 0.53,
	'Moo' => 1,
	'DateTime::Format::MySQL' => 0.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Fast-*' },
);
