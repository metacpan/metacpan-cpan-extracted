use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::Trace::ABIF',
    AUTHOR              => 'Nicola Vitacolonna <vitacolonna@appliedgenomics.org>',
    VERSION_FROM        => 'lib/Bio/Trace/ABIF.pm',
    ABSTRACT_FROM       => 'lib/Bio/Trace/ABIF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Trace-ABIF-*' },
);
