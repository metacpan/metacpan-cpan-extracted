use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Benchmark::Stopwatch',
    'VERSION_FROM' => 'lib/Benchmark/Stopwatch.pm',
    'PREREQ_PM'    => {
        'Carp'             => '0',
        'Clone'            => '0',
        'Data::Dumper'     => '0',
        'Test::LongString' => '0',
        'Test::More'       => '0',
        'Time::HiRes'      => '0',
    },
);
