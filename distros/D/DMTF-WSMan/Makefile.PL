use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DMTF::WSMan',
    AUTHOR              => 'Stephen James Hurd <shurd@broadcom.com>',
    VERSION_FROM        => 'lib/DMTF/WSMan.pm',
    ABSTRACT_FROM       => 'lib/DMTF/WSMan.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'LWP'        => 0,
        'LWP::Authen::Digest' => 0,
        'Data::UUID' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DMTF-WSMan-*' },
);
