use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Random::String',
    AUTHOR              => 'Ioakim (Makis) Marmaridis <m.marmaridis@gmail.com>',
    VERSION_FROM        => 'lib/Data/Random/String.pm',
    ABSTRACT_FROM       => 'lib/Data/Random/String.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Random-String-*' },
);
