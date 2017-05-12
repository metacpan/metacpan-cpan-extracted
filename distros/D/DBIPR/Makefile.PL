use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIPR',
    AUTHOR              => 'Joe Jiang <lamp.purl@gmail.com>',
    VERSION_FROM        => 'lib/DBIPR.pm',
    ABSTRACT_FROM       => 'lib/DBIPR.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBI' => 0,
        'DBD::Oracle' => 1.19,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIPR-*' },
);
