use 5.000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cache::Benchmark',
    AUTHOR              => 'Tobias Tacke <cpan@tobias-tacke.de>',
    VERSION_FROM        => 'lib/Cache/Benchmark.pm',
    ABSTRACT_FROM       => 'lib/Cache/Benchmark.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cache-Benchmark-*' },
);
