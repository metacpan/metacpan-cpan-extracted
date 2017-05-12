use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::PrioQ::SkewBinomial',
    AUTHOR              => 'Lukas Mai <l.mai @web.de>',
    VERSION_FROM        => 'lib/Data/PrioQ/SkewBinomial.pm',
    ABSTRACT_FROM       => 'lib/Data/PrioQ/SkewBinomial.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'constant' => '1.04',
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-PrioQ-SkewBinomial-*' },
);
