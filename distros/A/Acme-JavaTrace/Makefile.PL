use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile (
    NAME                => 'Acme::JavaTrace', 
    LICENSE             => 'perl', 
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Acme/JavaTrace.pm', 
    ABSTRACT_FROM       => 'lib/Acme/JavaTrace.pm', 
    PREREQ_PM           => {
        # prereqs
        'Data::Dumper'  => 0, 

        # build/test prereqs
        'Test'          => 0,
        'Test::More'    => 0,
    }, 
    PL_FILES            => {}, 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-JavaTrace-*' },
);
