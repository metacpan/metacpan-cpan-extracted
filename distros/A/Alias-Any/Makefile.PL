use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Alias::Any',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Alias/Any.pm',
    ABSTRACT_FROM       => 'lib/Alias/Any.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.012,
    PREREQ_PM => {
        'Test::More'       => 0,
        'Keyword::Simple'  => 0.003,
        'Keyword::Declare' => 0.001009,
        'Data::Alias'      => 1.21,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Alias-Any-*' },
);
