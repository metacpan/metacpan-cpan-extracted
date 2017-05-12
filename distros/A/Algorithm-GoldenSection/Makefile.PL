use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::GoldenSection',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Algorithm/GoldenSection.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/GoldenSection.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp'       => "1.08",
        'Readonly'   => "1.03",
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-GoldenSection-*' },
);
