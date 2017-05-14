package DBIx::Class::Tree::Mobius;
# ABSTRACT: Manage trees of data using the Möbius encoding (nested intervals with continued fraction)

use strict;
use warnings;

use bigint;

use Math::BigFloat;

use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata( 'strict_mode' => 1 );

__PACKAGE__->mk_classdata( 'parent_virtual_column' => 'parent' );

__PACKAGE__->mk_classdata( '_mobius_a_column' => 'mobius_a' );
__PACKAGE__->mk_classdata( '_mobius_b_column' => 'mobius_b' );
__PACKAGE__->mk_classdata( '_mobius_c_column' => 'mobius_c' );
__PACKAGE__->mk_classdata( '_mobius_d_column' => 'mobius_d' );
__PACKAGE__->mk_classdata( '_lft_column' => 'lft' );
__PACKAGE__->mk_classdata( '_rgt_column' => 'rgt' );
__PACKAGE__->mk_classdata( '_is_inner_column' => 'is_inner' );

sub add_mobius_tree_columns {
    my $class = shift;
    my %column_names = @_;

    #workaround SQL::Translator::Producer::MySQL bug
    no bigint;

    foreach my $name (qw/ mobius_a mobius_b mobius_c mobius_d lft rgt is_inner /) {
        next unless exists $column_names{$name};
        my $accessor = "_${name}_column";
        $class->$accessor( $column_names{$name} );
    }

    $class->add_columns(
        $class->_mobius_a_column => { data_type => 'BIGINT', is_nullable => 1, extra => { unsigned => 1} },
        $class->_mobius_b_column => { data_type => 'BIGINT', is_nullable => 1, extra => { unsigned => 1} },
        $class->_mobius_c_column => { data_type => 'BIGINT', is_nullable => 1, extra => { unsigned => 1} },
        $class->_mobius_d_column => { data_type => 'BIGINT', is_nullable => 1, extra => { unsigned => 1} },
        $class->_lft_column => { data_type => 'DOUBLE', is_nullable => 0, default_value => 1, extra => { unsigned => 1} },
        $class->_rgt_column => { data_type => 'DOUBLE', is_nullable => 1, default_value => undef, extra => { unsigned => 1} },
        $class->_is_inner_column => { data_type => "BOOLEAN", default_value => 0, is_nullable => 0 },
        );

    $class->add_unique_constraint( $class->_mobius_a_column . $class->_mobius_c_column, [ $class->_mobius_a_column, $class->_mobius_c_column ] );

    if ($class =~ /::([^:]+)$/) {

        $class->belongs_to( 'parent' => $1 => {
            "foreign.".$class->_mobius_a_column => "self.".$class->_mobius_b_column,
            "foreign.".$class->_mobius_c_column => "self.".$class->_mobius_d_column,
        });

        $class->has_many( '_children' => $1 => {
            "foreign.".$class->_mobius_b_column => "self.".$class->_mobius_a_column,
            "foreign.".$class->_mobius_d_column => "self.".$class->_mobius_c_column,
        }, { cascade_delete => 0 });
      
    }

    Math::BigFloat->accuracy(53); 

}

sub children {
    my $self = shift;
    return $self->is_leaf ? ( wantarray ? () : $self->result_source->resultset->search({ 0 => 1 }) ) : $self->_children(@_);
}

sub root_cond {
    my $self = shift;
        return ( $self->_mobius_b_column => 1, $self->_mobius_d_column => undef );
}

sub inner_cond {
    my $self = shift;
    return $self->_is_inner_column => 1 ;
}

sub leaf_cond {
    my $self = shift;
    return $self->_is_inner_column => 0 ;
}

sub _rational {
    my $i = shift;

    return unless ($i);
    return ($i, 1) unless (scalar @_ > 0);

    my ($num, $den) = _rational(@_);
    return ($num * $i + $den, $num);
}

sub _euclidean {
    my ($a, $c) = (Math::BigInt->new(shift), Math::BigInt->new(shift));
    return unless ($c);
    my ($quo, $rem) = $a->bdiv($c);
    return $rem == 0 ? $quo : ($quo, _euclidean($c, $rem));
}

sub _mobius {
    my $i = shift;

    return (1, 0, 0, 1) unless ($i);
    my ($a, $b, $c, $d) = _mobius(@_);
    return ($i * $a + $c, $i * $b + $d, $a, $b);
}

sub _mobius_encoding {
    my ($a, $b, $c, $d) = _mobius(@_);
    return wantarray ? ($a, $b, $c, $d) : sprintf("(${a}x + $b) / (${c}x + $d)");
}

sub _mobius_path {
    my ($a, $b, $c, $d) = @_;
    my @path = _euclidean($a, $c);
    return wantarray ? @path : join('.', @path);
}

sub _left_right {
    my ($a, $b, $c, $d) = @_;
    my $left = Math::BigFloat->new($a+$b)->bdiv($c+$d);
    my $right = Math::BigFloat->new($a)->bdiv($c);
    ($left, $right) = ($right, $left) if ($left > $right);
    if ($left == $right) {
        if (__PACKAGE__->strict_mode) {
            die("maximum depth has been reached.");
        } else {
            warn("maximum depth has been reached.");
        }
    }
    return wantarray ? ($left, $right) : sprintf("l=%.20f, r=%.20f", $left, $right);
}

sub new {
    my ($class, $attrs) = @_;
    $class = ref $class if ref $class;
  
    if (my $parent = delete($attrs->{$class->parent_virtual_column})) {
        # store aside explicitly parent
        my $new = $class->next::method($attrs);
        $new->{_explicit_parent} = $parent;
        return $new;
    } else {
        return $class->next::method($attrs);
    }
}

# always use the leftmost index available for better scalability
# index 1 is cannot be used mathematically
# index 2 is reserved for leaves

sub _available_mobius_index {
    my @children = @_;

    my $count = scalar @children + 3;
    foreach my $child (@children) {
        my @mpath = $child->mobius_path();
        my $index = pop @mpath;
        last if ($count > $index);
        $count--;
    }
    return $count;
}

sub available_mobius_index {
    my $self = shift;
    return _available_mobius_index( $self->_mobius_children->search({ $self->_mobius_a_column => { '!=' => undef } }, { order_by => $self->_mobius_a_column. ' DESC' } ) );
}

sub _mobius_parent {
    my $self = shift;
    return $self->parent || $self->result_source->resultset->new({});
}

sub _mobius_children {
    my $self = shift;
    return $self->in_storage ? $self->children : $self->result_source->resultset->search( { $self->root_cond } );
}

sub _child_encoding {
    my ($x, $pa, $pb, $pc, $pd) = @_;
    
    my ($a, $c) = ($pa * $x + $pb, $pc * $x + $pd);
    my ($b, $d) = ($pa, $pc);

    return wantarray ? ($a, $b, $c, $d, _left_right($a, $b, $c, $d)) : sprintf("(${a}x + $b) / (${c}x + $d)");
}
        
sub child_encoding {
    my $self = shift;
    my $x = shift;

    die ('cannot calculate child encoding without parent encoding') if ( $self->in_storage and not $self->get_column($self->_mobius_a_column) );

    my ($pa, $pc) = $self->in_storage ? ( $self->get_column($self->_mobius_a_column), $self->get_column($self->_mobius_c_column) ) : ( 1, 0 );
    my ($pb, $pd) = $self->in_storage ? ( $self->get_column($self->_mobius_b_column), $self->get_column($self->_mobius_d_column) ) : ( 0, 1 );
    return _child_encoding( $x, $pa, $pb, $pc, defined($pd) ? $pd : 0);
}

sub _abcd {
    my $self = shift;

    # matrix for the mathematic super root node (abstract parent of all root nodes)
    my ($a, $b, $c, $d) = ( 1, 0, 0, 1 );

    if ( $self->in_storage ) {

        if ( $self->is_leaf ) {

            ($a, $b, $c, $d) = $self->_mobius_parent->child_encoding( 2 );

        } else {
        
            ($a, $b, $c, $d) = (
                $self->get_column($self->_mobius_a_column),
                $self->get_column($self->_mobius_b_column),
                $self->get_column($self->_mobius_c_column),
                $self->get_column($self->_mobius_d_column) // 0,
                );
            
        }

    }

    return wantarray ? ($a, $b, $c, $d) : sprintf("(${a}x + $b) / (${c}x + $d)");
}

sub mobius_path {
    my $self = shift;
    my @path = _mobius_path( $self->_abcd );
    return wantarray ? @path : join('.', @path);
}

sub insert {
    my $self = shift;

    my $parent = $self; # default parent to virtual mathematic super root node ( no SQL record associated )

    if (exists $self->{_explicit_parent}) {

        $parent = $self->result_source->resultset->find( $self->{_explicit_parent} );
        $parent->make_inner_node();

    } 

    # mobius index 2 is the default encoding for all leaves
    my ($a, $b, $c, $d, $left, $right) = $parent->child_encoding( $self->get_column($self->_is_inner_column) ? $parent->available_mobius_index : 2 );
    
    # a and c are not stored for leaves
    if ($self->get_column($self->_is_inner_column)) {
        $self->store_column( $self->_mobius_a_column => $a );
        $self->store_column( $self->_mobius_c_column => $c );
    }

    # d=0 (root nodes) is coded as a null value to preserve SQL unique contrainst
    $self->store_column( $self->_mobius_d_column => ($d == 0) ? undef : $d );
    $self->store_column( $self->_mobius_b_column => $b );
    $self->store_column( $self->_lft_column => $left );
    $self->store_column( $self->_rgt_column => $right );
    
    my $r = $self->next::method(@_);

    $r->make_inner_node() unless ( $r->is_leaf );

    return $r;
}

sub depth {
    my $self = shift;
    my @path = $self->mobius_path();
    return scalar @path;
}

sub root {
    my $self = shift;
    return $self->parent ? $self->result_source->resultset->search( { $self->root_cond } )->search({
        $self->result_source->resultset->current_source_alias.'.'.$self->_lft_column => { '<' => $self->get_column($self->_rgt_column) },
        $self->result_source->resultset->current_source_alias.'.'.$self->_rgt_column => { '>' => $self->get_column($self->_lft_column) },
    })->first : $self;
}

sub is_root {
    my $self = shift;
    return $self->parent ? 0 : 1;
}

sub is_inner {
    my $self = shift;
    return $self->get_column($self->_is_inner_column) ? 1 : 0;
}

sub is_branch {
    my $self = shift;
    return ($self->parent && $self->get_column($self->_is_inner_column)) ? 1 : 0;
}

sub is_leaf {
    my $self = shift;
    return $self->get_column($self->_is_inner_column) ? 0 : 1;
}

sub siblings {
    my $self = shift;
    warn("siblings is broken in this version: return siblings + self");
    return $self->_mobius_parent->_mobius_children();
    # -or => {
    #     $self->result_source->resultset->current_source_alias.'.'.$self->_mobius_a_column => { '!=' => $self->get_column($self->_mobius_a_column) },
    #     $self->result_source->resultset->current_source_alias.'.'.$self->_mobius_c_column => { '!=' => $self->get_column($self->_mobius_c_column) },
    # },
}

sub leaf_children {
    my $self = shift;
    return $self->children->search({ $self->result_source->resultset->current_source_alias.'.'.$self->_is_inner_column => 0 });
}

sub inner_children {
    my $self = shift;
    return $self->children->search({ $self->result_source->resultset->current_source_alias.'.'.$self->_is_inner_column => 1 });
}

sub descendants {
    my $self = shift;

    return $self->result_source->resultset->search({
        $self->result_source->resultset->current_source_alias.'.'.$self->_lft_column => { '>' => $self->get_column($self->_lft_column) },
        $self->result_source->resultset->current_source_alias.'.'.$self->_rgt_column => { '<' => $self->get_column($self->_rgt_column) },
    });
}

sub leaves {
    my $self = shift;
    return $self->descendants->search({ $self->result_source->resultset->current_source_alias.'.'.$self->_is_inner_column => 0 });
}

sub inner_descendants {
    my $self = shift;

    return $self->descendants->search({ $self->result_source->resultset->current_source_alias.'.'.$self->_is_inner_column => 1 });
}

sub ancestors {
    my $self = shift;
        
    return $self->result_source->resultset->search({
        -and => {
            $self->result_source->resultset->current_source_alias.'.'.$self->_lft_column => { '<' => $self->get_column($self->_lft_column) },
            $self->result_source->resultset->current_source_alias.'.'.$self->_rgt_column => { '>' => $self->get_column($self->_rgt_column) },
        },
        $self->result_source->resultset->current_source_alias.'.'.$self->_lft_column => { '<' => $self->get_column($self->_rgt_column) },
        $self->result_source->resultset->current_source_alias.'.'.$self->_rgt_column => { '>' => $self->get_column($self->_lft_column) },
        $self->result_source->resultset->current_source_alias.'.'.$self->_mobius_a_column => { '!=' => $self->get_column($self->_mobius_a_column) },
        $self->result_source->resultset->current_source_alias.'.'.$self->_mobius_c_column => { '!=' => $self->get_column($self->_mobius_c_column) },
    },{ order_by => $self->_lft_column.' DESC' });
}
sub ascendants { return shift(@_)->ancestors(@_) }

sub make_inner_node {
    my $self = shift;

    if ( $self->in_storage and $self->is_leaf ) {

        my $parent = $self->_mobius_parent;
        my ($a, $b, $c, $d, $left, $right) = $parent->child_encoding( $parent->available_mobius_index );

        $self->update({
            $self->_is_inner_column => 1,
            $self->_mobius_a_column => $a,
            $self->_mobius_c_column => $c,
            $self->_lft_column => $left,
            $self->_rgt_column => $right,
        });

    }

}

sub _attach_child {
    my $self = shift;
    my $child = shift;

    my @grandchildren = $child->children();

    $self->make_inner_node();

    my ($a, $b, $c, $d, $left, $right) = $self->child_encoding( $child->get_column($self->_is_inner_column) ? $self->available_mobius_index : 2 );

    foreach my $grandchild (@grandchildren) {
        $grandchild->update( { $self->_mobius_b_column => undef, $self->_mobius_d_column => undef });
    }

    # only store a/c for inner node
    if ($child->get_column($self->_is_inner_column)) {
        $child->set_column( $self->_mobius_a_column => $a );
        $child->set_column( $self->_mobius_c_column => $c );
    }

    $child->update({ 
        $self->_mobius_b_column => $b,
        $self->_mobius_d_column => ($d == 0) ? undef : $d,
        $self->_lft_column => $left,
        $self->_rgt_column => $right,
    });

    $child->attach_child( @grandchildren );

}

sub attach_child {
    my $self = shift;

    foreach my $child (@_) {

        next if ( defined $child->get_column( $self->_mobius_b_column ) and defined  $child->get_column( $self->_mobius_d_column ) and
                  $child->get_column( $self->_mobius_b_column ) == $self->get_column( $self->_mobius_a_column ) and
                  $child->get_column( $self->_mobius_d_column ) == $self->get_column( $self->_mobius_c_column ));

        $self->_attach_child( $child );

    }
}

sub make_root {
    my $self = shift;

    next if ( $self->get_column( $self->_mobius_b_column ) == 1 and
              not $self->get_column( $self->_mobius_d_column ) );
    
    $self->result_source->resultset->new({})->_attach_child( $self );

}



1;

=encoding utf8

=head1 SYNOPSIS

Create a table for your tree data with the 7 special columns used by
Tree::Mobius.  By default, these columns are mobius_a mobius_b
mobius_b and mobius_d (bigint), lft and rgt (double float) and
is_inner (boolean). See the add_mobius_tree_columns method to change
the default names.

  CREATE TABLE employees (
    name TEXT NOT NULL
    mobius_a BIGINT unsigned,
    mobius_b BIGINT unsigned,
    mobius_c BIGINT unsigned,
    mobius_d BIGINT unsigned,
    lft DOUBLE unsigned NOT NULL DEFAULT '1',
    rgt DOUBLE unsigned,
    is_inner boolean NOT NULL DEFAULT '0',
  );

In your Schema or DB class add Tree::Mobius in the component list.

  __PACKAGE__->load_components(qw( Tree::Mobius ... ));

Call add_mobius_tree_columns.

  package My::Employee;
  __PACKAGE__->add_mobius_tree_columns();

That's it, now you can create and manipulate trees for your table.

  #!/usr/bin/perl
  use My::Employee;
  
  my $big_boss = My::Employee->create({ name => 'Larry W.' });
  my $boss = My::Employee->create({ name => 'John Doe' });
  my $employee = My::Employee->create({ name => 'No One' });
  
  $big_boss->attach_child( $boss );
  $boss->attach_child( $employee );

=head1 DESCRIPTION

This module provides methods for working with trees of data using a
Möbius encoding, a variant of 'Nested Intervals' tree encoding using
continued fraction. This a model to represent hierarchical information
in a SQL database that takes a complementary approach of both the
'Nested Sets' model and the 'Materialized Path' model.

The implementation has been heavily inspired by a Vadim Tropashko's
paper available online at http://arxiv.org/pdf/cs.DB/0402051 about
the Möbius encoding.

In general, a 'Nested Intervals' model has the same advantages that
'Nested Sets' over the 'Adjacency List', that is to say obtaining all
descendants requires only one SQL query rather than several recursive
queries.

Additionally, a 'Nested Intervals' model has two more advantages over
'Nested Sets' :

- Encoding is not volatile (no other node has to be relabeled whenever
  a new node is inserted in the database).

- There are no difficulties associated with querying ancestors.

The Möbius encoding is a particular encoding scheme of the 'Nested
Intervals' model that uses integer numbers economically to allow
better tree scaling and directly encode the material path of a node
using continued fraction (thus this model also relates somewhat with
the 'Materialized Path' model).

This implementation allows you to have several root trees and
corresponding trees in your database.

To allow better performance and scaling, Tree::Mobius uses the same
Möbius encoding for all leaves (non inner children) of a given node. A
unique Möbius encoding is later calculated only if a node becomes
'inner' (having at least one descendant).

The encoding is not volatile, but the depth is constrained by the
precision of SQL float type in the right and left column. The maximum
depth reachable is 8 levels with a simple SQL FLOAT, and 21 with a SQL
DOUBLE. The number of inner nodes of your trees are also constrained
by the maximum integer allowed for mobius_a, mobius_b, mobius_c and
mobius_d column (see CAVEATS AND LIMITATIONS).

Finally, a tradeoff of DBIx::Class::Tree::Mobius over other models is
the non-economical use of 7 SQL columns to encode each node.

=head1 METHODS

=head2 add_mobius_tree_columns

Declare the name of the columns for tree encoding and add them to the schema.

None of these columns should be modified outside of this module.

Multiple trees are allowed in the same table, each tree will have a unique value in the mobius_a_column.

=head2 attach_child

Attach a new child to a node.

If the child already has descendants, the entire sub-tree is moved recursively.

=head2 insert

This method is an override of the DBIx::Class' method.

The method is not meant to not be used directly but it allows one to
add a parent virtual column when calling the DBIx::Class method create.

This virtual column should be set with the primary key value of the parent.

  My::Employee->create({ name => 'Another Intern', parent => $boss->id });

=head2 parent

Returns a DBIx::Class Row of the parent of a node.

=head2 children

Returns a DBIx::Class resultset of all children (direct descendants) of a node.

=head2 leaf_children

Returns a DBIx::Class resultset of all children (direct descendants) of a node that do not possess any child themselves.

=head2 inner_children

Returns a DBIx::Class resultset of all children (direct descendants) of a node that possess one or more child.

=head2 descendants

Returns a DBIx::Class resultset of all descendants of a node (direct or not).

=head2 leaves

Returns a DBIx::Class resultset of all descendants of a node that do not possess any child themselves.

=head2 inner_descendants

Returns a DBIx::Class resultset of all descendants of a node that possess one or more child.

=head2 ancestors

Returns a DBIx::Class resultset of all ancestors of a node.

=head2 ascendants

An alias method for ancestors.

=head2 root

Returns a DBIx::Class resultset containing the root ancestor of a given node.

=head2 siblings

Returns a DBIx::Class resultset containing all the nodes with the same parent of a given node.

=head2 is_root

Returns 1 if the node has no parent, and 0 otherwise.

=head2 is_inner

Returns 1 if the node has at least one child, and 0 otherwise.

=head2 is_branch

Returns 1 if the node has at least one child and is not a root node, 0 otherwise.

=head2 is_leaf

Returns 1 if the node has no child, and 0 otherwise.

=head2 available_mobius_index

Returns the smallest mobius index available in the subtree of a given node.

=head2 child_encoding

Given a mobius index, return the mobius a,b,c,d column values.

=head2 depth
 	
Return the depth of a node in a tree (depth of a root node is 1).
 	
=head2 make_root
 	
Force a node to become a new tree root (if this node possess a subtree 
of descendants, it becomes a new tree).
 	
=head1 CAVEATS AND LIMITATIONS

=head2 'left-right' maximum depth

All functions should work as expected until a tree reaches the
'left-right' maximum depth. That is to say 8 levels if you declared
the two special columns 'lft' and 'rgt' as a SQL FLOAT, and 21 levels
if you declared them as a SQL DOUBLE. In the default 'strict mode',
the library will enforce this 'left-right' maximum and will die if you
try to add a child deeper.

You may desactivate this check and allow Tree::Mobius to create nodes
deeper than this maximum level.

  __PACKAGE__->strict_mode( 0 );

In this relaxed mode, only the function 'children' and 'parent' will
work correctly and you should not trust the results returned by
'descendants', 'leaves', 'inner_descendants', 'ancestors' for any node
deeper than the maximum level.

Please also note that there is a bug in SQLite
http://www.sqlite.org/src/tktview?name=1248e6cda8 that prevent use of
more than 15 decimal precision FLOAT. A workaround consists of
manually restricting the accuracy of float in Tree::Mobius after the
add_mobius_tree_columns call :

Math::BigFloat->accuracy(15); 


=head2 'mobius' maximum index

The Möbius representation (using 4 integers a,b,c,d) is limited by the
maximum value of the type 'integer' of the corresponding columns in
your SQL database. Specifically, this encoding only limits the number
of inner nodes (nodes with at least one child) representable on the
right side of the tree. The upper limit can be calculated using the
least favorable Tree::Mobius inner node materialized path (with the
highest index at each level, not counting leaves), either recursively
or using matrix multiplication.

For example, a 4 levels depth tree with 5 inner nodes at level 1, 5
children inner nodes at level 2 attached to the rightmost level 1
node, and again 5 children inner nodes at level 3 attached to the
rightmost level 2 node, the least favorable inner node materialized
path is '5.5.5' The corresponding Tree::Mobius path is derived adding
2 to each index, thus '7.7.7'. The least favorable Möbius
representation can now be calculated using the following matrix
multiplication:

    ( 7  1 ) . ( 7  1 ) . ( 7  1 ) = ( 2549  357 )
    ( 1  0 )   ( 1  0 )   ( 1  0 )   (  357  50  )

In our example, a=2549, b=357, c=357 and d=50 and all numbers are
within the limits of the database INT or BIGINT type. Thus this tree
can be encoded by Tree::Mobius.

Using this method, we can calculate the worst case inner node
materialized path for the following inner node depth and the maximum
value of a MySQL UNSIGNED INT, that is to say 4294967295.

 - 2 levels : 1623.1623  (the 1623th level 1 inner node has maximum 1623th inner descendants)
 - 3 levels : 253.253.253
 - 4 levels : 82.82.82.82
 - 5 levels : 38.38.38.38.38
 - 6 levels : 21.21.21.21.21.21
 - 7 levels : 13.13.13.13.13.13.13

The limits with MySQL UNSIGNED BIGINT (18446744073709551615) are :

 - 3  levels : 2642243.2642243.2642243
 - 4  levels : 65533.65533.65533.65533
 - 5  levels : 7129.7129.7129.7129.7129
 - 6  levels : 1623.1623.1623.1623.1623.1623
 - 7  levels : 563.563.563.563.563.563  
 - 8  levels : 253.253.253.253.253.253.253.253
 - 9  levels : 136.136.136.136.136.136.136.136.136
 - 10 levels : 82.82.82.82.82.82.82.82.82
 - 11 levels : 54.54.54.54.54.54.54.54.54.54.54
 - 12 levels : 38.38.38.38.38.38.38.38.38.38.38.38
 - 13 levels : 28.28.28.28.28.28.28.28.28.28.28.28.28
 - 14 levels : 21.21.21.21.21.21.21.21.21.21.21.21.21.21
 - 15 levels : 17.17.17.17.17.17.17.17.17.17.17.17.17.17.17
 - 16 levels : 13.13.13.13.13.13.13.13.13.13.13.13.13.13.13.13
 - 17 levels : 11.11.11.11.11.11.11.11.11.11.11.11.11.11.11.11.11
 - 18 levels : 9.9.9.9.9.9.9.9.9.9.9.9.9.9.9.9.9.9
 - 19 levels : 8.8.8.8.8.8.8.8.8.8.8.8.8.8.8.8.8.8.8
 - 20 levels : 7.7.7.7.7.7.7.7.7.7.7.7.7.7.7.7.7.7.7.7
 - 21 levels : 6.6.6.6.6.6.6.6.6.6.6.6.6.6.6.6.6.6.6.6.6

For all these scenarios, there are no constraint with the number of
leaves at any level.

=head2 backward compatibility with experimental version

Finally, early testers should note that the encoding used since
version 0.2000 is not compatible with the old encoding tested in
experimental developper versions 0.00002_01 and 0.00001_04.

=head1 INTERNAL

The Möbius encoding (ax+b)/(cx+d) can represent a tree giving the
following relationship between each parent node and it's nth child :

     Parent encoding = [ Pa, Pb, Pc, Pd ]

     Child encoding = [ Pa * n + Pc, Pb * n + Pd, Pa, Pb ]

Tree::Mobius can encode several trees using the convention that root nodes
of these trees are in fact children of an abstract mathematic super root node
(there will be no row in your database for it).

The Möbius represention of this super root node is (a, b, c, d) = ( 1, 0, 0, 1 )

=for Pod::Coverage new mobius_path root_cond inner_cond leaf_cond make_inner_node

