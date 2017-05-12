use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'AMPR::Rip44',
    AUTHOR        => q{Heikki Hannikainen, OH7LZB <hessu@hes.iki.fi>},
    VERSION_FROM  => 'lib/AMPR/Rip44.pm',
    ABSTRACT_FROM => 'lib/AMPR/Rip44.pm',
    EXE_FILES =>
      [ 'bin/rip44d', ],

    (
          ( !eval { ExtUtils::MakeMaker->VERSION(6.46) } )
        ? ( 'LICENSE' => 'EVVKTVH / ICCLEIYSIUYA' )
        : ()
    ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'IO::Socket::Multicast' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'AMPR-Rip44-*' },
);
