use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Std::Storable',
    AUTHOR              => 'Luke Meyer <luke@daeron.com>',
    VERSION_FROM        => 'lib/Class/Std/Storable.pm',
    ABSTRACT_FROM       => 'lib/Class/Std/Storable.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Std' => '0.0.4',
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Std-Storable-*' },
);
