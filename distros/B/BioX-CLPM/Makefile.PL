use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BioX::CLPM',
    AUTHOR              => 'Nathan Crabtree <crabtree@cpan.org>',
    VERSION_FROM        => 'lib/BioX/CLPM.pm',
    ABSTRACT_FROM       => 'lib/BioX/CLPM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BioX-CLPM-*' },
);
