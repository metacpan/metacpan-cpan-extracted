use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Coro::PriorityQueue',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Coro/PriorityQueue.pm',
    ABSTRACT            => '',
        ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE'=> 'BSD License')
        : ()),
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Coro-PriorityQueue-*' },
    PREREQ_PM => {
        'AnyEvent'   => 0,
        'Coro'       => 0,
        'List::Util' => 0,
        'POSIX'      => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
);
