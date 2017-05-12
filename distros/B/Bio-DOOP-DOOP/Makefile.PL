use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::DOOP::DOOP',
    AUTHOR              => 'Tibor Nagy <buldozer88@hotmail.com>',
    VERSION_FROM        => 'lib/Bio/DOOP/DOOP.pm',
    ABSTRACT_FROM       => 'lib/Bio/DOOP/DOOP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'GD'                 => 2.35,
        'DBI'                => 1.52,
        'Carp'               => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-DOOP-DOOP-*' },
);
