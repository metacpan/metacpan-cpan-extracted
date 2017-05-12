use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::BottomsUp',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/Acme/BottomsUp.pm',
    ABSTRACT_FROM       => 'lib/Acme/BottomsUp.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Filter::Simple' => 0.82,
        'PPI' => 1.110,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-BottomsUp-*' },
);
