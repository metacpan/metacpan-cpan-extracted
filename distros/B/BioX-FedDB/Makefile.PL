use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BioX::FedDB',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/BioX/FedDB.pm',
    ABSTRACT_FROM       => 'lib/BioX/FedDB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BioX-FedDB-*' },
);
