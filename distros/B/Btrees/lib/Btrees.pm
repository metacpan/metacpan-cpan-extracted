
package Btrees;
$VERSION=1.00;

require 5.000;
require Exporter;

=head1 NAME

    Btrees - Binary trees using the AVL balancing method.

=head1 SYNOPSIS

    # yes, do USE the package ...
    use Btrees;

    # no constructors

    # traverse a tree and invoke a function
    traverse( $tree, $func );

    # find a node in a balanced tree
    $node = bal_tree_find( $tree, $val $cmp );

    # add a node in a balanced tree, rebalancing if required 
    ($tree, $node) = bal_tree_add( $tree, $val, $cmp )

    # delete a node in a balanced tree, rebalancing if required 
    ($tree, $node) = bal_tree_del( $tree, $val , $cmp )

=head1 DESCRIPTION

    Btrees uses the AVL balancing method, by G. M. Adelson-Velskii
    and E.M. Landis. Bit scavenging, as done in low level languages like
    C, is not used for height balancing since this is too expensive for
    an interpreter. Instead the actual height of each subtree is stored
    at each node. A null pointer has a height of zero. A leaf a height of
    1. A nonleaf a height of 1 greater than the height of its two children.

=head1 AUTHOR

 Ron Squiers (ron@broadcom.com). Adapted from "Mastering Algorithms with
 Perl" by Jon Orwant, Jarkko Hietaniemi & John Macdonald. Copyright
 1999 O'Reilly and Associates, Inc. All right reserved. ISBN: 1-56592-398-7

=cut

@ISA = qw(Exporter);
@EXPORT = qw( traverse bal_tree_find bal_tree_add bal_tree_del list );

#########################################
#
# Method: list
#
# List $tree in order in turn
#
# list( $tree );
#
sub list {
    my $tree = shift or return undef;

    local $max = $tree->{height};
    sub List {
        my $tree = shift;

        my $height = $tree->{height} || $max;
	while( $max - $height ) { print "  "; $height++; }
        printf("0x%x\n", $tree->{val});
    }
    my $func = \&List;
    traverse( $tree, $func );
}

#########################################
#
# Method: traverse
#
# Traverse $tree in order, calling $func() for each element.
#    in turn 
# traverse( $tree, $func );
#
sub traverse {
    my $tree = shift or return;	# skip undef pointers
    my $func = shift;

    traverse( $tree->{left}, $func );
    &$func( $tree );
    traverse( $tree->{right}, $func );
}

#########################################
#
# Method: bal_tree_find
#
# Traverse $tree in order, calling $func() for each element.
#    in turn 
# $node = bal_tree_find( $tree, $val[, $cmp ] );
#
sub bal_tree_find {
    my( $tree, $val, $cmp) = @_;
    my $result;

    while ( $tree ) {
	my $relation = defined $cmp
	    ? $cmp->( $val, $tree->{val} )
	    : $val <=> $tree->{val};

	    ### Stop when the desired node if found.
	    return $tree if $relation == 0;

	    ### Go down the correct subtree.
	    $tree = $relation < 0 ? $tree->{left} : $tree->{right};
	}

	### The desired node doesn't exist.
	return undef;
}

#########################################
#
# Method: bal_tree_add
#
# Search $tree looking for a node that has the value $val,
#    add it if it does not already exist. 
# If provided, $cmp compares values instead of <=>. 
#
# ($tree, $node) = bal_tree_add( $tree, $val, $cmp )
# the return values:
#    $tree points to the (possible new or changed) subtree that
#	has resulted from the add operation.
#    $node points to the (possibly new) node that contains $val
#
sub bal_tree_add {
    my( $tree, $val, $cmp) = @_;
    my $result;

    unless ( $tree ) {
	$result = { 
		left	=> undef,
		right	=> undef,
		val	=> $val,
		height	=> 1
	    };
	return( $result, $result );
    }

    my $relation = defined $cmp
	? $cmp->( $val, $tree->{val} )
	: $val <=> $tree->{val};

    ### Stop when the desired node if found.
    return ( $tree, $tree ) if $relation == 0;

    ### Add to the correct subtree.
    if( $relation < 0 ) {
	($tree->{left}, $result) =
	    bal_tree_add ( $tree->{left}, $val, $cmp );
    } else {
	($tree->{right}, $result) =
	    bal_tree_add ( $tree->{right}, $val, $cmp );
    }

    ### Make sure that this level is balanced, return the
    ###    (possibly changed) top and the (possibly new) selected node. 
    return ( balance_tree( $tree ), $result );
}

#########################################
#
# Method: bal_tree_del
#
# Search $tree looking for a node that has the value $val,
#    and delete it if it does not already exist. 
# If provided, $cmp compares values instead of <=>. 
#
# ($tree, $node) = bal_tree_del( $tree, $val , $cmp )
#
# the return values:
#    $tree points to the (possible empty or changed) subtree that
#	has resulted from the delete operation.
#    if found, $node points to the node that contains $val
#    if not found, $node is undef 
#
sub bal_tree_del {
    # An empty (sub)tree does not contain the target.
    my $tree = shift or return (undef,undef);

    my ($val, $cmp) = @_;
    my $node;

    my $relation = defined $cmp
	? $cmp->( $val, $tree->{val} )
	: $val <=> $tree->{val};

    if( $relation != 0 ) {
	### Not this node, go down the tree.
	if( $relation < 0 ) {
	    ($tree->{left}, $node) =
		bal_tree_del ( $tree->{left}, $val, $cmp );
	} else {
	    ($tree->{right}, $node) =
		bal_tree_del ( $tree->{right}, $val, $cmp );
	}

	### No balancing required if it wasn't found. 
	return ( $tree, undef ) unless $node;
    } else {
	# Must delete this node. Remember it to return it,
	$node = $tree;

	# but splice the rest of the tree back together first
	$tree = bal_tree_join( $tree->{left}, $tree->{right} );

	# and make the deleted node forget its children (precaution
	# in case the caller tries to use the node).
	$node->{left} = $node->{right} = undef;
    }

    ### Make sure that this level is balanced, return the
    ###    (possibly undef) selected node.
    return ( balance_tree($tree), $node );
}

#########################################
#
# Method: bal_tree_join
#
# Join two trees together into a single tree
#
# the return values:
#    $tree points to the joined subtrees that has resulted from
#	the join operation.
#
sub bal_tree_join {
    my ($l, $r) = @_;

    ### Simple case - onr or both is null.
    return $l unless defined $r;
    return $r unless defined $l;

    ### Nope - we've got two real trees to merge here.
    my $top;

    if ( $l->{height} > $r->{height} ) {
	$top = $l;
	$top->{right} = bal_tree_join( $top->{right}, $r );
    } else {
	$top = $r;
	$top->{left} = bal_tree_join( $l, $top->{left} );
    }
    return balance_tree( $top );
}

#########################################
#
# Method: balance_tree
#
# Balance a potentially out of balance tree 
#
# the return values:
#    $tree points to the balanced tree root
#
sub balance_tree {
    ### An empty tree is balanced already.
    my $tree = shift or return undef;

    ### An empty link is height 0.
    my $lh = defined $tree->{left} && $tree->{left}{height};
    my $rh = defined $tree->{right} && $tree->{right}{height};

    ### Rebalance if needed, return the (possibly changed) root.
    if ( $lh > 1+$rh ) {
	return swing_right( $tree );
    } elsif ( $lh+1 < $rh ) {
	return swing_left( $tree );
    } else {
	### Tree is either perfectly balanced or off by one.
	### Just fix its height.
	set_height( $tree );
	return $tree;
    }
} 

#########################################
#
# Method: set_height
#
# Set height of a node 
#
sub set_height {
    my $tree = shift;

    my $p;
    ### get heights, an undef node is height 0.
    my $lh = defined ( $p = $tree->{left}  ) && $p->{height};
    my $rh = defined ( $p = $tree->{right} ) && $p->{height};
    $tree->{height} = $lh < $rh ? $rh+1 : $lh+1;
}

#########################################
#
# Method: $tree = swing_left( $tree )
#
# Change        t       to      r      or       rl
#              / \             / \            /    \ 
#             l   r           t   rr         t      r
#                / \         / \            / \    / \
#               rl  rr      l   rl         l  rll rlr rr
#              /  \            / \
#            rll  rlr        rll rlr
#
# t and r must both exist.
# The second form is used if height of rl is greater than height of rr
# (since the form would then lead to the height of t at least 2 more
# than the height of rr).
#
# changing to the second form is done in two steps, with first a move_right(r)
# and then a move_left(t), so it goes:
#
# Change        t       to      t   and then to   rl
#              / \             / \              /    \ 
#             l   r           l   rl           t      r
#                / \             / \          / \    / \
#               rl  rr         rll  r        l  rll rlr rr
#              /  \                / \
#            rll  rlr            rlr  rr
#
sub swing_left {
    my $tree = shift;

    my $r = $tree->{right};	# must exist
    my $rl = $r->{left};	# might exist
    my $rr = $r->{right};	# might exist
    my $l = $tree->{left};	# might exist

    ### get heights, an undef node has height 0
    my $lh = $l && $l->{height} || 0;
    my $rlh = $rl && $rl->{height} || 0;
    my $rrh = $rr && $rr->{height} || 0;

    if ( $rlh > $rrh ) {
	$tree->{right} = move_right( $r );
    }

    return move_left( $tree );
}

# and the opposite swing

sub swing_right {
    my $tree = shift;

    my $l = $tree->{left};	# must exist
    my $lr = $l->{right};	# might exist
    my $ll = $l->{left};	# might exist
    my $r = $tree->{right};	# might exist 

    ### get heights, an undef node has height 0
    my $rh = $r && $r->{height} || 0;
    my $lrh = $lr && $lr->{height} || 0;
    my $llh = $ll && $ll->{height} || 0;

    if ( $lrh > $llh ) {
	$tree->{left} = move_left( $l );
    }

    return move_right( $tree );
}

#########################################
#
# Method: $tree = move_left( $tree )
#
# Change        t       to      r
#              / \             / \
#             l   r           t   rr
#                / \         / \
#               rl  rr      l   rl
#
# caller has determined that t and r both exist
#    (l can be undef, so can one of rl and rr)
#
sub move_left {
    my $tree = shift;
    my $r = $tree->{right};
    my $rl = $r->{left};

    $tree->{right} = $rl;
    $r->{left} = $tree;
    set_height( $tree );
    set_height( $r );
    return $r;
}

#########################################
#
# Method: $tree = move_right( $tree )
#
# Change        t       to      l
#              / \             / \
#             l   r          ll   t
#            / \                 / \
#           ll  lr             lr   r
#
# caller has determined that t and l both exist
#    (r can be undef, so can one of ll and lr)
#
sub move_right {
    my $tree = shift;
    my $l = $tree->{left};
    my $lr = $l->{right};

    $tree->{left} = $lr;
    $l->{right} = $tree;
    set_height( $tree );
    set_height( $l );
    return $l;
}

#########################################
# That's all folks ...
#########################################
#
1;  # so that use() returns true

