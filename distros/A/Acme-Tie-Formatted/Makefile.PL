use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Tie::Formatted',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    VERSION_FROM        => 'lib/Acme/Tie/Formatted.pm',
    ABSTRACT_FROM       => 'lib/Acme/Tie/Formatted.pm',
    LICENSE             => 'artistic',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Tie-Formatted-*' },
);

