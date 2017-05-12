use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::KossyValidator',
    AUTHOR              => '扶凯 <iakuf@163.com>',
    VERSION_FROM        => 'lib/Dancer/Plugin/KossyValidator.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/KossyValidator.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-KossyValidator-*' },
);
