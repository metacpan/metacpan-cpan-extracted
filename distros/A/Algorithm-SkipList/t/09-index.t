#-*- mode: perl;-*-

package main;

use strict;

use Test::More tests => 30;

use Algorithm::SkipList 0.71;

my @Array = qw( A B C );

my $List = new Algorithm::SkipList;

foreach (@Array) {
  $List->insert($_, 1+$List->size);
}

{
  foreach (1..$List->size) {
    my $index = $_ - 1;
    my $node = $List->_node_by_index($index);
    ok($node,'positive ranges');
    ok($node->key_cmp( $List->key_by_index($index) ) == 0);
    ok($node->key_cmp( $List->last_key ) == 0);
    ok($List->value_by_index($index) == $_);
    ok($List->index_by_key( $List->key_by_index($index) ) == $index);
    ok($List->index_by_key( $List->last_key ) == $index);
  }

  foreach ((-$List->size)..-1) {

    my $index = $_;
    my $node = $List->_node_by_index($index);
    ok($node, 'negative ranges');
    ok($node->key_cmp( $List->key_by_index($index) ) == 0);
    ok($node->key_cmp( $List->last_key ) == 0);
    ok($List->value_by_index($index) == ($List->size+1+$_));
  }
}


# {
#   $[ = 1;

#   foreach (1..$List->size) {
#     my $index = $_;
#     my $node = $List->_node_by_index($index);
#     ok($node);
#     ok($node->key_cmp( $List->key_by_index($index) ) == 0);
#     ok($List->value_by_index($index) == $_);
#   }

#   foreach ((-$List->size)..-1) {

#     my $index = $_;
#     my $node = $List->_node_by_index($index);
#     ok($node);
#     ok($node->key_cmp( $List->key_by_index($index) ) == 0);
#     ok($List->value_by_index($index) == ($List->size+1+$_));

#   }

# }

