#!perl -w
use strict;
use Test::More;

use DBIx::Schema::DSL;

my $hoge = DBIx::Schema::DSL::Context->new;
ok $hoge;
ok $hoge->can('name');

done_testing;
