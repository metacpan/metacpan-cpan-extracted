use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Stardate',
    AUTHOR              => 'Chris Fedde <cfedde at cpan.org>',
    VERSION_FROM        => 'lib/Acme/Stardate.pm',
    ABSTRACT_FROM       => 'lib/Acme/Stardate.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/stardate' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Exporter' => 5.63,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Stardate-*' },
);
