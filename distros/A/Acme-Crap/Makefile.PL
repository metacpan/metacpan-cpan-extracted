use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Crap',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Acme/Crap.pm',
    ABSTRACT_FROM       => 'lib/Acme/Crap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Crap-*' },
);
