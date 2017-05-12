package DBIx::Class::Tree::AdjacencyList;
# vim: ts=8:sw=4:sts=4:et

use strict;
use warnings;

use base qw( DBIx::Class );
use Carp qw( croak );

=head1 NAME

DBIx::Class::Tree::AdjacencyList - Manage a tree of data using the common adjacency list model.

=head1 SYNOPSIS

Create a table for your tree data.

  CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_id INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL
  );

In your Schema or DB class add Tree::AdjacencyList to the top
of the component list.

  __PACKAGE__->load_components(qw( Tree::AdjacencyList ... ));

Specify the column that contains the parent ID of each row.

  package My::Employee;
  __PACKAGE__->parent_column('parent_id');

Optionally, automatically maintane a consistent tree structure.

  __PACKAGE__->repair_tree( 1 );

Thats it, now you can modify and analyze the tree.

  #!/usr/bin/perl
  use My::Employee;

  my $employee = My::Employee->create({ name=>'Matt S. Trout' });

  my $rs = $employee->children();
  my @siblings = $employee->children();

  my $parent = $employee->parent();
  $employee->parent( 7 );

=head1 DESCRIPTION

This module provides methods for working with adjacency lists.  The
adjacency list model is a very common way of representing a tree structure.
In this model each row in a table has a prent ID column that references the
primary key of another row in the same table.  Because of this the primary
key must only be one column and is usually some sort of integer.  The row
with a parent ID of 0 is the root node and is usually the parent of all
other rows.  Although, there is no limitation in this module that would
stop you from having multiple root nodes.

=head1 METHODS

=head2 parent_column

  __PACKAGE__->parent_column('parent_id');

Declares the name of the column that contains the self-referential
ID which defines the parent row.  This will create a has_many (children) 
and belongs_to (parent) relationship.

This method also sets up an additional has_many relationship called
parents which is useful when you want to treat an adjacency list
as a DAG.

=cut

__PACKAGE__->mk_classdata( '_parent_column' => 'parent_id' );

sub parent_column {
    my $class = shift;
    if (@_) {
        my $parent_col = shift;
        my $primary_col = ($class->primary_columns())[0];
        $class->belongs_to( '_parent' => $class => { "foreign.$primary_col" => "self.$parent_col" } );
        $class->has_many( 'children' => $class => { "foreign.$parent_col" => "self.$primary_col" } );
        $class->has_many( 'parents' => $class => { "foreign.$primary_col" => "self.$parent_col" }, { cascade_delete => 0, cascade_copy => 0 } );
        $class->_parent_column( $parent_col );
        return 1;
    }
    return $class->_parent_column();
}

=head2 repair_tree

  __PACKAGE__->repair_tree( 1 );

When set a true value this flag causes all changes to a node's parent to
trigger an integrity check on the tree.  If, when changing a node's parent
to one of it's descendents then all its children will first be moved to have
the same current parent, and then the node's parent is changed.

So, for example, if the tree is like this:

  A
    B
      C
      D
        E
    F

And you execute:

  $b->parent( $d );

Since D is a descendant of B then all of D's siblings get their parent
changed to A.  Then B's parent is set to D.

  A
    C
    D
      B
      E
    F

=cut

__PACKAGE__->mk_classdata( 'repair_tree' => 0 );

=head2 parent

  my $parent = $employee->parent();
  $employee->parent( $parent_obj );
  $employee->parent( $parent_id );

Retrieves the object's parent object, or changes the object's
parent to the specified parent or parent ID.  If you would like
to make the object the root node, just set the parent to 0.

If you are setting the parent then 0 will be returned if the
specified parent is already the object's parent and 1 on
success.

=cut

sub parent {
    my $self = shift;
    if (@_) {
        my $new_parent = shift;
        my $parent_col = $self->_parent_column();
        if (ref($new_parent)) {
            $new_parent = $new_parent->id() || croak('Parent object does not have an ID');;
        }
        return 0 if ($new_parent == ($self->get_column($parent_col)||0));

        if ($self->repair_tree()) {
            my $found    = $self->has_descendant( $new_parent );
            if ($found) {
                my $children = $self->children();

                while (my $child = $children->next()) {
                    $child->parent( $self->$parent_col() );
                }
            }
        }

        $self->set_column( $parent_col => $new_parent );
        $self->update();
        return 1;
    }
    return $self->_parent();
}
=head2 ancestors

  @list = $employee->ancestors();

Returns a list of ancestors starting with a record's
parent and moving toward the tree root.

=cut

sub ancestors {
    my $self = shift;
    my @ancestors = ();
    my $rec = $self;
    while ($rec = $rec->parent) {
      push(@ancestors, $rec);
    }
    return @ancestors;
}


=head2 has_descendant

  if ($employee->has_descendant( $id )) { ... }

Returns true if the object has a descendant with the
specified ID.

=cut

sub has_descendant {
    my ($self, $find_id) = @_;

    my $children = $self->children();
    while (my $child = $children->next()) {
        if ($child->id() eq $find_id) {
            return 1;
        }
        return 1 if ($child->has_descendant( $find_id ));
    }

    return 0;
}

=head2 parents

  my $parents = $node->parents();
  my @parents = $node->parents();

This has_many relationship is not that useful as it will
never return more than one parent due to the one-to-many
structure of adjacency lists.  The reason this relationship
is defined is so that this tree type may be treated as if
it was a DAG.

=head2 children

  my $children_rs = $employee->children();
  my @children = $employee->children();

Returns a list or record set, depending on context, of all
the objects one level below the current one.  This method
is created when parent_column() is called, which sets up a
has_many relationship called children.

=head2 attach_child

  $parent->attach_child( $child );
  $parent->attach_child( $child, $child, ... );

Sets the child, or children, to the new parent.  Returns 1
on success and returns 0 if the parent object already has
the child.

=cut

sub attach_child {
    my $self = shift;
    my $return = 1;
    foreach my $child (@_) {
        $child->parent( $self );
    }
    return $return;
}

=head2 siblings

  my $rs = $node->siblings();
  my @siblings = $node->siblings();

Returns either a result set or an array of all other objects
with the same parent as the calling object.

=cut

sub siblings {
    my( $self ) = @_;
    my $parent_col = $self->_parent_column;
    my $primary_col = ($self->primary_columns())[0];
    my $rs = $self->result_source->resultset->search(
        {
            $parent_col => $self->get_column($parent_col),
            $primary_col => { '!=' => $self->get_column($primary_col) },
        },
    );
    return $rs->all() if (wantarray());
    return $rs;
}

=head2 attach_sibling

  $obj->attach_sibling( $sibling );
  $obj->attach_sibling( $sibling, $sibling, ... );

Sets the passed in object(s) to have the same parent
as the calling object.  Returns 1 on success and
0 if the sibling already has the same parent.

=cut

sub attach_sibling {
    my $self = shift;
    my $return = 1;
    foreach my $node (@_) {
        $return = 0 if (!$node->parent( $self->parent() ));
    }
    return $return;
}

=head2 is_leaf

  if ($obj->is_leaf()) { ... }

Returns 1 if the object has no children, and 0 otherwise.

=cut

sub is_leaf {
    my( $self ) = @_;

    my $has_child = $self->children_rs->count();

    return $has_child ? 0 : 1;
}

=head2 is_root

  if ($obj->is_root()) { ... }

Returns 1 if the object has no parent, and 0 otherwise.

=cut

sub is_root {
    my( $self ) = @_;
    return ( $self->get_column( $self->_parent_column ) ? 0 : 1 );
}

=head2 is_branch

  if ($obj->is_branch()) { ... }

Returns 1 if the object has a parent and has children.
Returns 0 otherwise.

=cut

sub is_branch {
    my( $self ) = @_;
    return ( ($self->is_leaf() or $self->is_root()) ? 0 : 1 );
}

=head2 set_primary_key

This method is an override of DBIx::Class' method for setting the
class' primary key column(s).  This method passes control right on
to the normal method after first validating that only one column is
being selected as a primary key.  If more than one column is then
an error will be thrown.

=cut

sub set_primary_key {
    my $self = shift;
    if (@_>1) {
        croak('You may only specify a single column as the primary key for adjacency tree classes');
    }
    return $self->next::method( @_ );
}

1;
__END__

=head1 INHERITED METHODS

=head2 DBIx::Class

=over 4

=item *

L<mk_classdata|DBIx::Class/mk_classdata>

=item *

L<component_base_class|DBIx::Class/component_base_class>

=back

=head2 DBIx::Class::Componentised

=over 4

=item *

L<inject_base|DBIx::Class::Componentised/inject_base>

=item *

L<load_components|DBIx::Class::Componentised/load_components>

=item *

L<load_own_components|DBIx::Class::Componentised/load_own_components>

=back

=head2 Class::Data::Accessor

=over 4

=item *

L<mk_classaccessor|Class::Data::Accessor/mk_classaccessor>

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

