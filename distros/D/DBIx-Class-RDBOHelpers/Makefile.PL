use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::Class::RDBOHelpers',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/DBIx/Class/RDBOHelpers.pm',
    ABSTRACT_FROM => 'lib/DBIx/Class/RDBOHelpers.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'          => 0,
        'DBIx::Class'         => 0,
        'DBICx::TestDatabase' => 0,
        'Data::Dump'          => 0,

    },
    META_MERGE => {
        resources => {
            license  => 'http://dev.perl.org/licenses/',
            homepage => 'https://github.com/karpet/dbix-class-rdbohelpers',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-RDBOHelpers',
            repository => 'https://github.com/karpet/dbix-class-rdbohelpers',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBIx-Class-RDBOHelpers-*' },
);
