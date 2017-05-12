use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Siteswap',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Acme/Siteswap.pm',
    ABSTRACT_FROM       => 'lib/Acme/Siteswap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Siteswap-*' },
);
