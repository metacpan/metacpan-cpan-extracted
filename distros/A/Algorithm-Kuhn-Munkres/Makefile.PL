use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::Kuhn::Munkres',
    AUTHOR              => 'Martin-Louis Bright <mlbright@gmail.com>',
    VERSION_FROM        => 'lib/Algorithm/Kuhn/Munkres.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/Kuhn/Munkres.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-Kuhn-Munkres-*' },
);
