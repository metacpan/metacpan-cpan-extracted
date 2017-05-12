use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::HexDump::XXD',
    AUTHOR              => 'Flavio Poletti <flavio [at] polettix [dot] it>',
    VERSION_FROM        => 'VERSION',
    ABSTRACT_FROM       => 'VERSION',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-HexDump-XXD-*' },
);
