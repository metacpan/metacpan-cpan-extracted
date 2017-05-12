use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::DataMigration',
    AUTHOR              => 'Dan Friedman <lamech@cpan.org>',
    VERSION_FROM        => 'lib/Class/DBI/DataMigration.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/DataMigration.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp::Assert'                       => '0.17',
        'Class::Accessor'                    => '0.18',
        'Class::DBI::Loader'                 => '0.01',
        'Class::Data::Inheritable'           => '0.02',
        'YAML'                               => '0.35',
        'Class::Trigger'                     => '0.08',
        'Ima::DBI'                           => '0.31',
        'UNIVERSAL::moniker'                 => '0.06',
        'DBI'                                => '1.38',
        'Class::WhiteHole'                   => '0.04',
        'Class::DBI'                         => '0.94',
        'Class::DBI::SQLite'                 => '0.02',
        'DBD::SQLite'                        => '0.28',
        'Class::DBI::Test::TempDB'           => '0'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-DataMigration-*' },
);
