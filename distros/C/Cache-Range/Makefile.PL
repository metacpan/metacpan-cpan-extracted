use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cache::Range',
    AUTHOR              => q{Rob Hoelz <rhoelz@inoc.com>},
    VERSION_FROM        => 'lib/Cache/Range.pm',
    ABSTRACT_FROM       => 'lib/Cache/Range.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Tree::R'          => '0.06',
        'Cache'            => 0,
        'Storable'         => 0,
        'namespace::clean' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cache-Range-*' },
);
