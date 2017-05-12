use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DMTF::CIM::WSMan',
    AUTHOR              => 'Stephen James Hurd <shurd@broadcom.com>',
    VERSION_FROM        => 'lib/DMTF/CIM/WSMan.pm',
    ABSTRACT_FROM       => 'lib/DMTF/CIM/WSMan.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'URI'        => 0,
        'URI::Escape'=> 0,
        'DMTF::WSMan'=> 0,
        'DMTF::CIM'  => 0,
        'DMTF::CIM::Instance'=> 0,
        'XML::Twig'  => 0,
        'DateTime::Duration'=> 0,
        'MIME::Base64'=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DMTF-CIM-WSMan-*' },
);
