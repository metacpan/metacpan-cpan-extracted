use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::XHTML_Table',
    AUTHOR           => q{jeffa <jeffa@cpan.org>},
    VERSION_FROM     => 'lib/DBIx/XHTML_Table.pm',
    ABSTRACT_FROM    => 'lib/DBIx/XHTML_Table.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'DBI'        => 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'https://github.com/jeffa/DBIx-XHTML_Table',
                repository => 'https://github.com/jeffa/DBIx-XHTML_Table.git',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-XHTML_Table-*' },
);
