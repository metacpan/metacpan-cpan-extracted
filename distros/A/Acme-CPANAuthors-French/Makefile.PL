use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::CPANAuthors::French',
    LICENSE             => 'perl',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Acme/CPANAuthors/French.pm',
    ABSTRACT_FROM       => 'lib/Acme/CPANAuthors/French.pm',
    PREREQ_PM => {
        # prereqs
        'Acme::CPANAuthors' => '0.04',

        # build/test prereqs
        'Test::More'        => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-CPANAuthors-French-*' },
);
