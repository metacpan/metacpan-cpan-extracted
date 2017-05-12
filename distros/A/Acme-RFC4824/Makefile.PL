use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::RFC4824',
    AUTHOR              => 'Alexander Klink <alech@cpan.org>',
    VERSION_FROM        => 'lib/Acme/RFC4824.pm',
    ABSTRACT_FROM       => 'lib/Acme/RFC4824.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose'      => '0.18',
    },
    LICENSE             => 'perl',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-RFC4824-*' },
);
