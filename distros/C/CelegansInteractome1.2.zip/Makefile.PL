use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CelegansInteractome',
    AUTHOR           => q{Damien OHalloran <damienoh@gwu.edu>},
    VERSION_FROM     => 'lib/CelegansInteractome.pm',
    ABSTRACT_FROM    => 'lib/CelegansInteractome.pm',
    LICENSE          => 'gpl_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'GraphViz'              => 0,
        'LWP::Simple'              => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CelegansInteractome-*' },
);
