#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME         => 'DBIx::Model',
    ABSTRACT     => 'DBI extension for table_info as objects',
    AUTHOR       => 'Mark Lawrence <nomad@null.net>',
    VERSION_FROM => 'lib/DBIx/Model.pm',
    LICENSE      => 'gpl_3',
    EXE_FILES    => [],
    test         => {
        RECURSIVE_TEST_FILES => 1,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker =>
              { web => 'https//github.com/mlawren/p5-DBIx-Model/issues', },
            homepage   => 'https//github.com/mlawren/p5-DBIx-Model',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-DBIx-Model.git',
                web  => 'https//github.com/mlawren/p5-DBIx-Model',
            }
        },
    },
);
