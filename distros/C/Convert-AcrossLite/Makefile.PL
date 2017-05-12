use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Convert::AcrossLite',
    AUTHOR              => 'Doug Sparling <dougsparling@yahoo.com>',
    VERSION_FROM        => 'lib/Convert/AcrossLite.pm',
    ABSTRACT_FROM       => 'lib/Convert/AcrossLite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Convert-AcrossLite-*' },
);
