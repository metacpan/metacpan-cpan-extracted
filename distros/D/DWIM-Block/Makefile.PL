use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DWIM::Block',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/DWIM/Block.pm',
    ABSTRACT_FROM       => 'lib/DWIM/Block.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.022,
    PREREQ_PM => {
        'Test::More'     => 0,
        'PPR'            => 0,
        'AI::Chat'       => 0,
        'Filter::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DWIM-Block-*' },
);
