use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::ExceptionEater',
    AUTHOR              => 'Kyle Hasselbacher <kyleha@gmail.com>',
    VERSION_FROM        => 'lib/Acme/ExceptionEater.pm',
    ABSTRACT_FROM       => 'lib/Acme/ExceptionEater.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-ExceptionEater-*' },
);
