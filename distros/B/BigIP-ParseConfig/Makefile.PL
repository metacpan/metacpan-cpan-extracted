use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BigIP::ParseConfig',
    ABSTRACT            => 'F5/BigIP configuration parser',
    AUTHOR              => 'Scott Schneider <sschneid@gmail.com>',
    VERSION_FROM        => 'lib/BigIP/ParseConfig.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BigIP-ParseConfig-*' },
);

