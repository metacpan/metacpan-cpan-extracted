use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Code::ART',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Code/ART.pm',
    ABSTRACT_FROM       => 'lib/Code/ART.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.016,
    PREREQ_PM => {
        'Test::More'  => 0,
        'PPR'         => 0.000027,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Code-ART-*' },
);
