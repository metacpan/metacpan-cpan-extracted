# A node of a linked list.

package DataStructure::LinkedList::Node;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util qw(weaken);

=pod

=head1 NAME

DataStructure::LinkedList::Node

=head1 SYNOPSIS

A single node (element) in a L<DataStructure::LinkedList>.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

You can’t build a node directly. Instead you can call one of the accessors of a
L<DataStructure::LinkedList> or some of the methods below.

Note that a B<DataStructure::LinkedList::Node> does not hold a reference on its
parent list. So a node becomes invalid when the last reference to its list is
deleted as the list itself will be destroyed. But you should also not depend on
this behavior as it might be fixed in the future.

=cut

# The constructor is private and should be called only by this package and its
# parent.
sub new ($class, $list, $next, $value) {
  my $self = bless {
    list => $list,
    next => $next,
    value => $value,
  }, $class;
  weaken($self->{list});
  return $self;
}

=pod

=head2 METHODS

All the functions below are class methods that should be called on a
B<DataStructure::LinkedList::Node> object.

=head3 I<value()>

Returns the value held by this node.

=cut

sub value ($self) {
  return $self->{value};
}

=pod

=head3 I<next()>

Returns the next B<DataStructure::DoubleList::Node> in this list or B<undef>
if the current object is the last node in its list.

The current node can still be used after that call.

=cut

sub next ($self) {
  return $self->{next};
}

=pod

=head3 I<insert_after($value)>

Inserts a new node in the list after the current one, with the given value and
returns that new node.

The current node can still be used after that call.

=cut

sub insert_after ($self, $value) {
   my $new_node = new(ref $self, $self->{list}, $self->{next}, $value);
   $self->{next} = $new_node;
   $self->{list}{size}++;
   return $new_node;
}

# Delete the node, assuming that it is the first node of the list.
sub _delete_first ($self) {
  my $value = $self->{value};
  $self->{list}{size}--;
  undef %{$self};
  return $value;
}

1;
