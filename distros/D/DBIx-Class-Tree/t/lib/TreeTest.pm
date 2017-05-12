package TreeTest;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use TreeTest::Schema;

our $NODE_COUNT = 80;

sub count_tests {
    my $count = 17;
    if( TreeTest::Schema::Node->can('position_column') ){
        $count ++;
    }
    return $count;
}

sub run_tests {
    my $schema = TreeTest::Schema->connect();
    my $nodes = $schema->resultset('Node');
    my $root = $nodes->create({ name=>'root' });
    my @parents = (
        1,1,3,4,4,3,3,8,8,10,10,8,8,3,3,16,3,3,1,20,1,22,22,24,24,22,27,27,29,29,27,32,32,34,34,36,34,38,38,40,40,42,42,44,44,46,44,44,49,44,51,51,53,51,55,55,57,57,55,60,55,62,55,64,64,55,67,67,55,70,70,55,55,51,51,76,76,78,78,76
    );

    foreach my $parent_id (@parents) {
        my $node = $nodes->create({ name=>'child' });
        $node->parent( $parent_id );
    }

    ok( ($nodes->count()==81), 'correct number of nodes in random tree' );
    ok( ($nodes->find(3)->children->count()==7), 'node 3 has correct number of children' );
    ok( ($nodes->find(22)->children->count()==3), 'node 22 has correct number of children' );

    my $child = ($nodes->find(22)->children->all())[0];
    $child->parent( $nodes->find(3) );
    ok( ($nodes->find(3)->children->count()==8), 'node 3 has correct number of children' );
    ok( ($nodes->find(3)->siblings->count()==3), 'node 3 has correct number of siblings' );
    ok( ($nodes->find(22)->children->count()==2), 'node 22 has correct number of children' );
    ok( ($nodes->find(22)->siblings->count()==3), 'node 22 has correct number of siblings' );

    $nodes->find(22)->attach_child( $nodes->find(3) );
    ok( ($nodes->find(22)->children->count()==3), 'node 22 has correct number of children' );
    ok( ($nodes->find(22)->siblings->count()==2), 'node 22 has correct number of siblings' );

    $nodes->find(22)->attach_sibling( $nodes->find(3) );
    ok( ($nodes->find(22)->children->count()==2), 'node 22 has correct number of children' );
    ok( ($nodes->find(22)->siblings->count()==3), 'node 22 has correct number of siblings' );

    ok( ($nodes->find(22)->parents->count()==1), 'node 22 has correct number of parents' );
    ok( (($nodes->find(22)->parents->all())[0]->id()==$nodes->find(22)->parent->id()), 'node 22 parent matches parents' );

    my @ancestors = $nodes->find(44)->ancestors();
    ok( scalar(@ancestors)==8, 'node 44 has correct number of ancestors' );
    ok( $ancestors[0]->id == $nodes->find(44)->parent_id, 'node 44\'s first ancestor is its parent' );
    ok( $ancestors[-1]->name eq 'root', 'node 44\'s last ancestor is root' );

    if( TreeTest::Schema::Node->can('position_column') ){
        ok( check_positions(scalar $root->children()), 'positions are correct' );
    }

    lives_and ( sub {
      is( $nodes->find(3)->copy({name => 'special'})->name,'special','copy test');
    }, 'copy does not throw');
}

sub check_positions {
    my $nodes = shift;
    my $position = 0;
    while (my $node = $nodes->next()) {
        $position ++;
        return 0 if ($node->position() != $position);
        return 0 if ( !check_positions(scalar $node->children()) );
    }
    return 1;
}

1;
