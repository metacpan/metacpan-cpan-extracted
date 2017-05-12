use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::VersionedDDL',
    AUTHOR        => q{Dan Horne <dan.horne@redbone.co.nz>},
    VERSION_FROM  => 'lib/DBIx/VersionedDDL.pm',
    ABSTRACT_FROM => 'lib/DBIx/VersionedDDL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    EXE_FILES => ['script/migrate_schema'],
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose'        => 0,
        'DBI'          => 0,
        'Text::CSV'    => 0,
        'DBD::SQLite'  => 0,
        'Pod::Usage'   => 0,
        'MooseX::Attribute::ENV' => 0,
        'MooseX::Object::Pluggable' => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'DBIx-VersionedDDL-*'},
);
