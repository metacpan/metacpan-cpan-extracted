#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME          => 'DBIx::ThinSQL',
    ABSTRACT_FROM => 'lib/DBIx/ThinSQL.pm',
    AUTHOR        => 'Mark Lawrence <nomad@null.net>',
    VERSION_FROM  => 'lib/DBIx/ThinSQL.pm',
    LICENSE       => 'gpl_3',
    test          => { RECURSIVE_TEST_FILES => 1, },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        no_index    => {
            package => [
                qw/
                  DBIx::ThinSQL::Driver
                  DBIx::ThinSQL::Driver::Pg
                  DBIx::ThinSQL::Driver::SQLite
                  DBIx::ThinSQL::bind_value
                  DBIx::ThinSQL::case
                  DBIx::ThinSQL::db
                  DBIx::ThinSQL::expr
                  DBIx::ThinSQL::list
                  DBIx::ThinSQL::query
                  DBIx::ThinSQL::quote_identifier
                  DBIx::ThinSQL::quote_value
                  DBIx::ThinSQL::st
                  DBIx::ThinSQL::table
                  DBIx::ThinSQL::values
                  /
            ],
        },
        resources => {
            bugtracker =>
              { web => 'https//github.com/mlawren/p5-DBIx-ThinSQL/issues', },
            homepage   => 'https//github.com/mlawren/p5-DBIx-ThinSQL',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-DBIx-ThinSQL.git',
                web  => 'https//github.com/mlawren/p5-DBIx-ThinSQL',
            }
        },
    },
);

package MY;
use File::ShareDir::Install qw(postamble);
