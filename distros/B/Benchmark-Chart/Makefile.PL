use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Benchmark::Chart',
    AUTHOR           => q{Tomas Dohnalek <dohnto@gmail.com>},
    VERSION_FROM     => 'lib/Benchmark/Chart.pm',
    ABSTRACT_FROM    => 'lib/Benchmark/Chart.pm',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Smart::Args'  => 0.12,
        'Chart::Gnuplot' => 0.21
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Benchmark-Chart-*' },
);
