use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'B::OptreeShortestPath',
    AUTHOR              => 'Joshua ben Jore <twists@gmail.com>',
    VERSION_FROM        => 'lib/B/OptreeShortestPath.pm',
    ABSTRACT_FROM       => 'lib/B/OptreeShortestPath.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'B-OptreeShortestPath-*' },
);
