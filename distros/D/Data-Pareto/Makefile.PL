use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Pareto',
    AUTHOR              => 'Przemyslaw Wesolek <jest@go.art.pl>',
    VERSION_FROM        => 'lib/Data/Pareto.pm',
    ABSTRACT_FROM       => 'lib/Data/Pareto.pm',
    LICENSE             => 'artistic_2',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Scalar::Util' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Pareto-*' },
);
