use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Dx',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Data/Dx.pm',
    ABSTRACT_FROM       => 'lib/Data/Dx.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.012,
    PREREQ_PM => {
        'Test::More'       => 0,
        'Keyword::Declare' => '0.001003',
        'Term::ANSIColor'  => '4.06',
        'Data::Dump'       => '1.23',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Dx-*' },
);
