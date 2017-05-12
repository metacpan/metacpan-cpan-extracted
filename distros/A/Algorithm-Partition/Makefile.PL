use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::Partition',
    AUTHOR              => 'Dmitri Tikhonov <dtikhonov@yahoo.com>',
    VERSION_FROM        => 'lib/Algorithm/Partition.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/Partition.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-Partition-*' },
    LICENSE             => 'perl',
);
