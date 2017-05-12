use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DMTF::CIM',
    AUTHOR              => 'Stephen James Hurd <shurd@broadcom.com>',
    VERSION_FROM        => 'lib/DMTF/CIM.pm',
    ABSTRACT_FROM       => 'lib/DMTF/CIM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DMTF-CIM-*' },
);
