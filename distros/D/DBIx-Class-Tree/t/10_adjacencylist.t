# vim: filetype=perl:ts=8:sw=4:sts=4:et
use strict;
use warnings;
use lib 't/lib';

use Test::More;

BEGIN {   # This must happen before the schema is loaded

  require TreeTest::Schema::Node;

  TreeTest::Schema::Node->load_components(qw(
    Tree::AdjacencyList
  ));

  TreeTest::Schema::Node->parent_column( 'parent_id' );
}

use TreeTest;

my $tests = TreeTest::count_tests();
plan tests => $tests;
TreeTest::run_tests();

1;
