use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Benchmark::Serialize',
    AUTHOR              => q{Peter Makholm <peter@makholm.net>},
    VERSION_FROM        => 'lib/Benchmark/Serialize.pm',
    ABSTRACT_FROM       => 'lib/Benchmark/Serialize.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'UNIVERSAL::require' => 0,
        'Test::More' => 0,
        'Test::Deep::NoTest' => 0,
    },
    META_MERGE          => {
        resources => {
            repository => 'http://github.com/pmakholm/benchmark-serialize-perl',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Benchmark-Serialize-*' },
);
