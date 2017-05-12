use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::MySperqlOO',
    AUTHOR              => 'Roger A Hall <roger@iosea.com>',
    ABSTRACT            => 'OO One line SQL statements with MySQL',
    VERSION_FROM        => 'lib/DBIx/MySperqlOO.pm',
    PL_FILES            => {},
    PREREQ_PM           => { 'DBI' => 1.607, 'DBD::mysql' => 2.9004, 'Class::Std' => 0.0.8, 'Class::Std::Utils' => 0.0.3 },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-MySperqlOO-*' },
);
