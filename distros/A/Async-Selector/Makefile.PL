use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Async::Selector',
    AUTHOR              => q{Toshio Ito <toshioito@cpan.org>},
    VERSION_FROM        => 'lib/Async/Selector.pm',
    ABSTRACT_FROM       => 'lib/Async/Selector.pm',
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
        'List::Util' => 0,
        'Test::Warn' => 0,
        'Test::Exception' => 0,
        'FindBin' => 0,
        'Test::Memory::Cycle' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Async-Selector-*' },
);
