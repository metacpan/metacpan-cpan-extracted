use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'DBIx::Connect::FromConfig',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/DBIx/Connect/FromConfig.pm',
    ABSTRACT_FROM       => 'lib/DBIx/Connect/FromConfig.pm',
    PREREQ_PM => {
        # prereqs
        'Carp'          => 0,
        'DBI'           => 0,

        # build/test prereqs
        'Test::More'    => 0,
    },
    META_MERGE          => {
        resources       => {
            repository  => "https://github.com/maddingue/DBIx-Connect-FromConfig.git",
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-Connect-FromConfig-*' },
);
