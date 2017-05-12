use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DMTF::CIM::MOF',
    AUTHOR              => 'Stephen James Hurd <shurd@broadcom.com>',
    VERSION_FROM        => 'lib/DMTF/CIM/MOF.pm',
    ABSTRACT_FROM       => 'lib/DMTF/CIM/MOF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'DMTF::CIM'  => 0,
        'Storable'   => 0,
        'Exporter'   => '5.57',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DMTF-CIM-MOF-*' },
);
