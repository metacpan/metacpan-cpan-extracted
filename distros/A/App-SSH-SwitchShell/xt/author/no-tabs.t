#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.021

use Test::NoTabs;

all_perl_files_ok( grep { -d } qw( bin lib t xt ) );
