package DBIx::Table::TestDataGenerator::Tree;
use Moo;

use strict;
use warnings;

use Data::GUID;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use List::Util qw / max /;

has root => (
    is       => 'ro',
    required => 1,
);

has nodes => (
    is       => 'rw',
    required => 1,
);

has handled => (
    is       => 'ro',
    default  => sub { return [] },
    init_arg => undef,
);

sub add_auto_child {
    my ( $self, $min_children, $max_level, $min_roots, $add_root_node ) = @_;
    my $auto_child_id = Data::GUID->new->as_hex;
    return [
        $auto_child_id,
        $self->add_child(
            $auto_child_id, $min_children, $max_level,
            $min_roots,     $add_root_node
        )
    ];
}

sub remove_leaf_node {
    my ( $self, $parent_id, $child_id ) = @_;
    my @children = grep { $_ ne $child_id } @{ $self->nodes->{$parent_id} };
    $self->nodes->{$parent_id} = \@children;
    delete $self->nodes->{$parent_id} unless @{ $self->nodes->{$parent_id} };
    return;
}

sub add_leaf_node {
    my ( $self, $parent_id, $child_id ) = @_;
    push @{ $self->nodes->{$parent_id} }, $child_id;
    $self->_alter_stack_tail($child_id);
    return;
}

#return min ($num_wanted, #children of $parent) children of $parent
sub _get_children {
    my ( $self, $parent, $min_children ) = @_;
    return [] unless $self->nodes->{$parent};
    my $n = @{ $self->nodes->{$parent} };
    $n = $min_children if $min_children < $n;
    return [ @{ $self->nodes->{$parent} }[ 0 .. $n - 1 ] ];
}

{
    my @stack;
    my @nodes_to_delete;

    sub add_child {
        my ( $self, $child_id, $min_children, $max_level, $min_roots,
            $add_root_node )
          = @_;

        $self->_initialize_stack($min_children) unless @stack;

        if ($add_root_node) {
            push @{ $self->nodes->{ $self->root } }, $child_id;
            my @roots = @{ $stack[0] };
            push @roots, $child_id;
            $stack[0] = \@roots;
            return $self->root;
        }

        while (1) {
            if ( @{ $stack[-1] } == 1 ) {
                $self->_add_existing_children_to_stack( ${ $stack[-1] }[0],
                    $min_children );

                #need to add a new child here in case the node
                #had no children before!
                if ( @{ $stack[-1] } < $min_children + 1 ) {
                    return $self->_add_missing_child($child_id);
                }
            }
            else {
                if ( @{ $stack[-1] } > 1 ) {
                    if ( ( @stack == 1 && @{ $stack[0] } >= $min_roots + 1 )
                        || ( @stack > 1
                            && @{ $stack[-1] } >= $min_children + 1 ) )
                    {
                        $self->_handle_full_tail($max_level);
                    }
                    else {
                        return $self->_add_missing_child($child_id);
                    }
                }
                else {
                    $self->_handle_empty_tail();
                }
            }
        }
        return;
    }

    sub _initialize_stack {
        my ( $self, $min_children ) = @_;
        @stack = ( [ $self->root ] );
        $self->_add_existing_children_to_stack( ${ $stack[0] }[0],
            $min_children );
    }

    sub _delete_handled_nodes {
        my ($self) = @_;
        foreach my $node (@nodes_to_delete) {
            delete $self->nodes->{$node};
        }
        @nodes_to_delete = ();
        return;
    }

    sub _add_existing_children_to_stack {
        my ( $self, $a, $min_children ) = @_;
        my @list = @{ $self->_get_children( $a, $min_children ) };
        unshift @list, $a;
        $stack[-1] = \@list;
        push @nodes_to_delete, @list;
        return;
    }

    sub _add_missing_child {
        my ( $self, $new_child ) = @_;
        push @nodes_to_delete, $new_child;
        my @list = @{ $stack[-1] };
        push @list, $new_child;
        $stack[-1] = \@list;
        push @{ $self->nodes->{ $list[0] } }, $new_child;
        return $list[0];
    }

    sub _handle_full_tail {
        my ( $self, $max_level ) = @_;
        if ( @stack == $max_level ) {
            if ( $max_level > 1 ) {
                push @nodes_to_delete, @{ $stack[-1] };
                if ( $max_level == 1 ) {
                    $stack[-1] = [ $self->root ];
                    $self->_delete_handled_nodes();
                }
                else {
                    $stack[-1] = [];
                }
            }
        }
        else {
            my @list = @{ $stack[-1] };
            my $b    = pop @list;
            $stack[-1] = \@list;
            push @stack, [$b];
        }
        return;
    }

    sub _handle_empty_tail {
        my ($self) = @_;
        if ( @stack == 2 && @{ $stack[-2] } == 1 ) {
            @stack = ( [ $self->root ] );
            $self->_delete_handled_nodes();
            return;
        }
        my @list = @{ $stack[-2] };
        if ( @list == 1 ) {
            pop @stack;
            $stack[-1] = [];
        }
        else {
            my $b = pop @list;
            $stack[-2] = \@list;
            $stack[-1] = [$b];
        }
        return;
    }

    sub _alter_stack_tail {
        my ( $self, $new_id ) = @_;
        @{ $stack[-1] }[-1] = $new_id;
        return;
    }

}

sub depth {
    my ( $self, $tree ) = @_;
    $tree = $self->nodes unless $tree;
    my @non_roots = map { @{ $tree->{$_} } } keys %{$tree};
    return 1 unless @non_roots;
    my %tree = map +( $_ => $tree->{$_} || [] ), @non_roots;
    return 1 + $self->depth( \%tree );
}

1;    # End of DBIx::Table::TestDataGenerator::Tree

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::Tree - tree builder, used internally to handle self-references in the target table

=head1 DESCRIPTION

This module has nothing to do with databases and could be used on its own. It handles ordered directed graphs which we will call trees here. The trees are represented as hashes where the keys are seen as parent identifiers and the values are references to arrays containing the child identifiers as elements. The purpose of the current class is to allow to determine insertion points for new nodes based on criteria defined by the corresponding parameters. I did not want to write yet another tree handling module, but I could not find anything on CPAN fitting my special needs.

The method add_child adds a node in a place automatically determined and satisfying constraints defined by the parameters passed to it. (Implementation detail: For a branch where no more descendants need to be added, the base node is removed from the tree to avoid reconsidering the branch, therefore the tree will sometimes grow and sometimes be pruned.)

The algorithm used here is not based on recursion, I could not find a way to use this approach without sacrificing performance (to be honest, I could not find a complete solution based on recursion). Using the handled accessor and the @stack variable we maintain a state allowing us to continue to fill the tree relative to the place where we left it.

A note on terminology: When using the current class for TestDataGenerator, the root node of the represented tree does not correspond to a record in the target database, what we have called root records there corresponds to the (direct) children of the root node here. So root here does not mean the same thing as in the TestDataGenerator code.

=head1 SUBROUTINES/METHODS

=head2 root

Accessor for the (artificial) root of the tree, its id being determined as a GUID.

=head2 nodes

Accessor for the data structure representing the handled tree.

=head2 handled

Contains the handled nodes at level 1, internal use only.

=head2 add_auto_child

Arguments:

=over 4

=item * $min_children: minimum number of child nodes to be added

=item * $max_level: maximum level at which a child nodes will be inserted

=back

Returns a pair [ $id, $parent_id ] where the first element is the automatically determined id of the added child node and the second that of its parent as determined by the current method. As a side-effect, the tree is modified accordingly.

The purpose of the current method is the following: There are cases where we do not yet know the exact id a child node will get, e.g. in the case of an auto-incremented primary key column. For these cases, the current method allows to insert a child using an automatically determined (temporary) id. add_auto_child of course lets add_child do the hard work.

=head2 remove_leaf_node

Arguments:

=over 4

=item * $parent_id: id of parent of node to delete from tree

=item * $child_id: id of node to delete from tree

=back

Removes the node with id $child_id from the tree, should be used for leaf nodes only (this is not enforced but taken into account here) and will not work correctly for non-leaf nodes. Is used when handling auto-incremented primary key columns to remove temporary nodes.

=head2 add_leaf_node

Arguments:

=over 4

=item * $parent_id: id of parent of leaf node to add

=item * $child_id: id of leaf node to add to tree

=back

Adds the leaf node with id $child_id to the tree. Also updates the @stack.

=head2 add_child

Arguments:

=over 4

=item * $child_id

Identifier of the current child node to be added.

=item * $min_children

For each handled parent node, this is the minimum number of child nodes to be added. The minimum number may not be reached if the parent node is the last one for which add_child is called.

=item * $max_level

Maximum depth at which nodes are added, must be at least 2 since all nodes other than root nodes are at least at level 2. The returned result is the identifier of the node at which the child note has been appended. The position of the appended node is determined in a depth-first manner.

=back

The main method of the current class, handles adding a node to a tree under the described constraints and in a depth-first, right-to-left manner.

=head2 depth

Returns the maximum depth of a tree, children of the root node having level 1.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.
