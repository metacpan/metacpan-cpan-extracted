use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::MetaSyntactic::daleks',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Acme/MetaSyntactic/daleks.pm',
    ABSTRACT_FROM       => 'lib/Acme/MetaSyntactic/daleks.pm',
    PREREQ_PM => {
        # prereqs
        'Acme::MetaSyntactic'   => '0.99',

        # build/test prereqs
        'Test::More'    => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-MetaSyntactic-daleks-*' },
);
