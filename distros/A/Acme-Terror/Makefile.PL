use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Terror',
    AUTHOR              => 'Matt Galisa <mrdelayer@gmail.com>',
    VERSION_FROM        => 'lib/Acme/Terror.pm',
    ABSTRACT_FROM       => 'lib/Acme/Terror.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Terror-*' },
);
