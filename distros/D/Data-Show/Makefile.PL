use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Show',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Data/Show.pm',
    ABSTRACT_FROM       => 'lib/Data/Show.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Dump' => 1.17,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Show-*' },
);
