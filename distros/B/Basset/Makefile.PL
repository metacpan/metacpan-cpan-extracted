use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Basset::Object',
    AUTHOR              => 'Jim Thomason <jim@jimandkoka.com>',
    VERSION_FROM        => 'lib/Basset/Object.pm',
    ABSTRACT_FROM       => 'lib/Basset/Object.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Dumper' => 0,
        'File::Temp' => 0,
        'Carp'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Basset-*' },
);
