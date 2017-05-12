use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::TLB',
    AUTHOR              => 'Jerome Eteve <jerome@eteve.net>',
    VERSION_FROM        => 'lib/Class/TLB.pm',
    ABSTRACT_FROM       => 'lib/Class/TLB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::PriorityQueue' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-TLB-*' },
);
