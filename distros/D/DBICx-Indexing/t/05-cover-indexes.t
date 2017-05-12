#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;

use DBICx::Indexing;
use My::Test::Utils;

my $table = My::Test::Utils->test_table;

my @test_cases = (
  [1, qw( a )],
  [1, qw( a b )],
  [1, qw( d )],
  [1, qw( e )],
  [1, qw( e f )],
  [0, qw( a c )],
  [0, qw( d e )],
  [0, qw( e f g )],
  [0, qw( a b c d )],
);

for my $spec (@test_cases) {
  my $result = shift @$spec;

  is(DBICx::Indexing::_has_cover_index($table, $spec), $result);
}

done_testing();
