# A node of a double linked list.

package DataStructure::DoubleList::Node;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util qw(weaken);

=pod

=head1 NAME

DataStructure::DoubleList::Node

=head1 SYNOPSIS

A single node (element) in a L<DataStructure::DoubleList>.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

You can’t build a node directly. Instead you can call one of the accessors of a
L<DataStructure::DoubleList> or some of the methods below.

Note that a B<DataStructure::DoubleList::Node> does not hold a reference on its
parent list. So a node becomes invalid when the last reference to its list is
deleted as the list itself will be destroyed. But you should also not depend on
this behavior as it might be fixed in the future.

=cut

# The constructor is private and should be called only by this package and its
# parent.
sub new ($class, $list, $prev, $next, $value) {
  my $self = bless {
    list => $list,
    prev => $prev,
    next => $next,
    value => $value,
  }, $class;
  weaken($self->{list});
  return $self;
}

=pod

=head2 METHODS

All the functions below are class methods that should be called on a
B<DataStructure::DoubleList::Node> object.

=head3 I<value()>

Returns the value held by this node.

=cut

sub value ($self) {
  return $self->{value};
}

=pod

=head3 I<prev()>

Returns the previous B<DataStructure::DoubleList::Node> in this list or B<undef>
if the current object is the first node in its list.

The current node can still be used after that call.

=cut

sub prev ($self) {
  return $self->{prev};
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
   my $new_node = new(ref $self, $self->{list}, $self, $self->{next}, $value);
   if (defined $self->{next}) {
     $self->{next}{prev} = $new_node;
   } else {
     $self->{list}{last} = $new_node;
   }
   $self->{next} = $new_node;
   $self->{list}{size}++;
   return $new_node;
}


=pod

=head3 I<insert_before($value)>

Inserts a new node before in the list before the current one, with the given
value and returns that new node.

The current node can still be used after that call.

=cut

sub insert_before ($self, $value) {
   my $new_node = new(ref $self, $self->{list}, $self->{prev}, $self, $value);
   if (defined $self->{prev}) {
     $self->{prev}{next} = $new_node;
   } else {
     $self->{list}{first} = $new_node;
   }
   $self->{prev} = $new_node;
   $self->{list}{size}++;
   return;
}


=pod

=head3 I<delete()>

Removes the node from the list and returns the value that it help value. The
node becomes invalid and can no longer be used.

=cut

sub delete ($self) {
  my $value = $self->{value};
  $self->_delete();
  return $value;
}

# Removes the current element without returning its value.
sub _delete ($self) {
  my ($prev, $next) = ($self->{prev}, $self->{next});
  if (defined $prev) {
    $prev->{next} = $next;
  } else {
    $self->{list}{first} = $next;
  }
  if (defined $next) {
    $next->{prev} = $prev;
  } else {
    $self->{list}{last} = $prev;
  }
  $self->{list}{size}--;
  undef %{$self};
  return;
}

1;
