use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::TreeDraw',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Data/TreeDraw.pm',
    ABSTRACT_FROM       => 'lib/Data/TreeDraw.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'version'               => 0,
        'Scalar::Util'          => "1.22", 
        'Class::MOP'            => "0.95",
        'Text::SimpleTable'     => "2.0",
        'Carp'                  => "1.08",
        'MRO::Compat'   => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-TreeDraw-*' },
);
