#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use Bio::Chado::Schema::Test;

# shorthand for writing left and right indices
sub lr($$) {  left_idx => shift, right_idx => shift }

my $schema = Bio::Chado::Schema::Test->init_schema();
my $phylotree_rs  = $schema->resultset('Phylogeny::Phylotree');
my $phylonodes_rs = $schema->resultset('Phylogeny::Phylonode');
$phylonodes_rs->delete;

$schema->txn_do(sub {

    my $test_tree =
        [
          1, 20,
          [ 2, 19,
            [ 3, 10,
              [4,5],
              [6,7],
              [8,9],
             ],
            [ 11, 12 ],
            [ 13, 18,
              [ 14, 15 ],
              [ 16, 17 ],
             ],
           ],
         ];

    my $phylotree = $phylotree_rs->create({
        name   => 'FakeTree',
        dbxref => {
            db => { name => 'null' },
            accession => 'FakeTree'
           },
    });

    _load_tree( $phylotree, $test_tree );
});

is( $phylonodes_rs->count, 10, '10 phylonodes loaded' );

my $whole_tree = $phylonodes_rs->search({},{ order_by => 'phylonode_id', rows => 1 })
                               ->single
                               ->descendants;

is( $whole_tree->count, 9,
    'all_children called on root phylonode gives all the phylonodes below the root'
   );


#################
sub _load_tree {
    my ( $tree, $data, $parent ) = @_;

    my %new_node;
    ( @new_node{'left_idx','right_idx'}, my @children ) = @$data;
    $new_node{parent_phylonode_id} = $parent->phylonode_id if $parent;

    my $child = $tree->add_to_phylonodes( \%new_node );

    _load_tree( $tree, $_, $child ) for @children;
}


done_testing;

