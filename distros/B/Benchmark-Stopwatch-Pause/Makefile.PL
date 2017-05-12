use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Benchmark::Stopwatch::Pause',
    AUTHOR              => 'Ben Hengst <notbenh@cpan.org>',
    VERSION_FROM        => 'lib/Benchmark/Stopwatch/Pause.pm',
    ABSTRACT_FROM       => 'lib/Benchmark/Stopwatch/Pause.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Benchmark::Stopwatch' => 0.03,
        'Time::HiRes' => 0,
        'Clone' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Benchmark-Stopwatch-Pause-*' },
);
