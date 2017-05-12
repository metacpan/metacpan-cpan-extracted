package DBIx::Class::Tree::AdjacencyList::Ordered;
# vim: ts=8:sw=4:sts=4:et

use strict;
use warnings;

use base qw( DBIx::Class );
use Carp qw( croak );

__PACKAGE__->load_components(qw(
    Ordered
    Tree::AdjacencyList
));

=head1 NAME

DBIx::Class::Tree::AdjacencyList::Ordered - Glue DBIx::Class::Ordered and DBIx::Class::Tree::AdjacencyList together.

=head1 SYNOPSIS

Create a table for your tree data.

  CREATE TABLE items (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_id INTEGER NOT NULL DEFAULT 0,
    position INTEGER NOT NULL,
    name TEXT NOT NULL
  );

In your Schema or DB class add Tree::AdjacencyList::Ordered 
to the front of the component list.

  __PACKAGE__->load_components(qw( Tree::AdjacencyList::Ordered ... ));

Specify the column that contains the parent ID and position of each row.

  package My::Employee;
  __PACKAGE__->position_column('position');
  __PACKAGE__->parent_column('parent_id');

This module provides a few extra methods beyond what 
L<DBIx::Class::Ordered> and L<DBIx::Class::Tree::AdjacencyList> 
already provide.

  my $parent = $item->parent();
  $item->parent( $parent_obj );
  $item->parent( $parent_id );
  
  my $children_rs = $item->children();
  my @children = $item->children();
  
  $parent->append_child( $child );
  $parent->prepend_child( $child );
  
  $this->attach_before( $that );
  $this->attach_after( $that );

=head1 DESCRIPTION

This module provides methods for working with adjacency lists and ordered 
rows.  All of the methods that L<DBIx::Class::Ordered> and 
L<DBIx::Class::Tree::AdjacencyList> provide are available with this module.

=head1 METHODS

=head2 parent_column

  __PACKAGE__->parent_column('parent_id');

Works the same as AdjacencyList's parent_column() method, but it 
declares the children() has many relationship to be ordered by the 
position column.

=cut

sub parent_column {
    my $class = shift;
    my $position_col = $class->position_column() || croak('You must call position_column() before calling parent_column()');
    if (@_) {
        $class->grouping_column( @_ );
        $class->next::method( @_ );
        $class->relationship_info('children')->{attrs}->{order_by} = $position_col;
        return 1;
    }
    return $class->grouping_column;
}

=head2 parent

  my $parent = $item->parent();
  $item->parent( $parent_obj );
  $item->parent( $parent_id );

This method overrides AdjacencyList's parent() method but 
modifies it so that the object is moved to the last position, 
then the parent is changed, and then it is moved to the last 
position of the new list, thus maintaining the intergrity of 
the ordered lists.

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
        $self->move_last;
        $self->set_column( $parent_col => $new_parent );
        $self->set_column(
            $self->position_column() => 
                $self->result_source->resultset->search(
                    {$self->_grouping_clause()}
                )->count() + 1
        );
        $self->update();
        return 1;
    }
    return $self->_parent();
}

=head2 children

  my $children_rs = $item->children();
  my @children = $item->children();

This method works just like it does in the 
DBIx::Class::Tree::AdjacencyList module except it 
orders the children by there position.

=head2 append_child

  $parent->append_child( $child );

Sets the child to have the specified parent and moves the 
child to the last position.

=cut

sub append_child {
    my( $self, $child ) = @_;
    $child->parent( $self );
}

=head2 prepend_child

  $parent->prepend_child( $child );

Sets the child to have the specified parent and moves the 
child to the first position.

=cut

sub prepend_child {
    my( $self, $child ) = @_;
    $child->parent( $self );
    $child->move_first();
}

=head2 attach_before

  $this->attach_before( $that );

Attaches the object at the position just before the 
calling object's position.

=cut

sub attach_before {
    my( $self, $sibling ) = @_;
    $sibling->parent( $self->parent() );
    $sibling->move_to( $self->get_column($self->position_column()) );
}

=head2 attach_after

  $this->attach_after( $that );

Attaches the object at the position just after the 
calling object's position.

=cut

sub attach_after {
    my( $self, $sibling ) = @_;
    $sibling->parent( $self->parent() );
    $sibling->move_to( $self->get_column($self->position_column()) + 1 );
}

1;
__END__

=head1 INHERITED METHODS

=head2 DBIx::Class::Ordered

=over 4

=item *

L<siblings|DBIx::Class::Ordered/siblings>

=item *

L<first_sibling|DBIx::Class::Ordered/first_sibling>

=item *

L<last_sibling|DBIx::Class::Ordered/last_sibling>

=item *

L<previous_sibling|DBIx::Class::Ordered/previous_sibling>

=item *

L<next_sibling|DBIx::Class::Ordered/next_sibling>

=item *

L<move_previous|DBIx::Class::Ordered/move_previous>

=item *

L<move_next|DBIx::Class::Ordered/move_next>

=item *

L<move_first|DBIx::Class::Ordered/move_first>

=item *

L<move_last|DBIx::Class::Ordered/move_last>

=item *

L<move_to|DBIx::Class::Ordered/move_to>

=item *

L<insert|DBIx::Class::Ordered/insert>

=item *

L<delete|DBIx::Class::Ordered/delete>

=back

=head2 DBIx::Class::Tree::AdjacencyList

=over 4

=item *

L<parent_column|DBIx::Class::Tree::AdjacencyList/parent_column>

=item *

L<parent|DBIx::Class::Tree::AdjacencyList/parent>

=item *

L<attach_child|DBIx::Class::Tree::AdjacencyList/attach_child>

=item *

L<siblings|DBIx::Class::Tree::AdjacencyList/siblings>

=item *

L<attach_sibling|DBIx::Class::Tree::AdjacencyList/attach_sibling>

=back

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

