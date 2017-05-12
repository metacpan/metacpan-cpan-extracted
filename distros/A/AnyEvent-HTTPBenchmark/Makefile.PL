use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::HTTPBenchmark',
    AUTHOR              => q{Naim Shafiev <naim@cpan.org>},
    VERSION_FROM        => 'lib/AnyEvent/HTTPBenchmark.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/HTTPBenchmark.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'AnyEvent::HTTP' => 1.45,
        'common::sense' => 3.0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-HTTPBenchmark-*' },
    EXE_FILES => ['benchmark.pl'] ,
);
