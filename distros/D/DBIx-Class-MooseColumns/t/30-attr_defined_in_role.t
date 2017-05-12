#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use Moose::Util qw(apply_all_roles);

# must be a BEGIN b/c the first test is in a BEGIN, too :-(
BEGIN {
  require Moose;
  plan skip_all => 'Using DBIx::Class::MooseColumns in roles is not supported under Moose 1.x'
    if $Moose::VERSION < 1.99;
}

# test for the role being applied smoothly

BEGIN {
  require TestSchema::Result::CD;
  lives_and {
    warnings_are {
      apply_all_roles('TestSchema::Result::CD', 'TestSchema::Role::HasTitle');
    } [];
  } "applying the role to a result class does not throw nor warn";
}

use Test::DBIx::Class;

fixtures_ok 'basic', 'installed the basic fixtures from configuration files';

# tests for ->add_column() being called for an attribute defined in a role

{
  lives_and {
    cmp_deeply(
      Schema->resultset('CD')->result_source->column_info('title'),
      superhashof({
        is_nullable => 1,
      })
    );
  } "column_info of 'title' contains ('is_nullable' => 1)";
}

done_testing;
