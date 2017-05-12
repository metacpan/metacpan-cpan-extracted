use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Async::Queue',
    AUTHOR              => q{Toshio Ito <debug.ito@gmail.com>},
    VERSION_FROM        => 'lib/Async/Queue.pm',
    ABSTRACT_FROM       => 'lib/Async/Queue.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'Scalar::Util' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'FindBin' => 0,
        'Test::Builder' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Async-Queue-*' },
);
