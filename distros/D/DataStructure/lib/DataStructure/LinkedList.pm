# A linked list data-structure.

package DataStructure::LinkedList;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use DataStructure::LinkedList::Node;

use parent qw(DataStructure::Queue);

package DataStructure::ReverseLinkedList {
  use parent qw(DataStructure::LinkedList DataStructure::Queue DataStructure::Stack);
}

=pod

=head1 NAME

DataStructure::LinkedList

=head1 SYNOPSIS

A linked list data-structure, written in pure Perl.

See also L<DataStructure::DoubleList> for a double-linked list version that
offers a richer interface.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

C<< DataStructure::LinkedList->new(%options) >>

Creates an empty list.

The following options are available:

=over 4

=item reverse

By default this class implements the standard C<shift> and C<unshift> methods
that operate on the beginning of the list and the C<push> method that operates
on the end of the list. And C<pop> is a synonym for C<shift> (so not the
opposite of C<push>).

If the C<reverse> option is set to a true value then the semantics of the list
is reversed and C<pop> and C<push> operate on the beginning of the list,
C<unshift> operates on the end of the list and C<shift> becomes a synonym for
C<pop>.

=back

=cut

sub new ($class, %options) {
  if ($options{reverse}) {
    die unless $class eq 'DataStructure::LinkedList';
    $class = 'DataStructure::ReverseLinkedList';
  }
  return bless {
    size => 0,
    first => undef,
    last => undef,
    reverse => $options{reverse} // 0,
  }, $class;
}

=pod

=head2 METHODS

All the functions below are class methods that should be called on a
B<DataStructure::LinkedList> object. Unless documented otherwise, they run in
constant time.

=over 4

=item first()

Returns the first L<DataStructure::LinkedList::Node> of the list, or B<undef> if
the list is empty.

=cut

sub first ($self) {
  return $self->{first};
}

=pod

=item last()

Returns the last L<DataStructure::LinkedList::Node> of the list, or B<undef> if
the list is empty.

=cut

sub last ($self) {
  return $self->{last};
}

# Actual unshift that always operates on the beginning of the list.
sub _unshift ($self, $value) {
  my $new_node = DataStructure::LinkedList::Node->new($self, $self->{first}, $value);
  $self->{first} = $new_node;
  $self->{last} = $new_node unless defined $self->{last};
  $self->{size}++;
  return $new_node;
}

# Actual push that always operates on the end of the list.
sub _push ($self, $value) {
  my $new_node = DataStructure::LinkedList::Node->new($self, undef, $value);
  if (defined $self->{last}) {
    $self->{last}{next} = $new_node;
  } else {
    $self->{first} = $new_node;
  }
  $self->{last} = $new_node;
  $self->{size}++;
  return $new_node;
}

# Actual shift that always operates on the beginning of the list.
sub _shift ($self) {
  return unless defined $self->{first};
  my $old_first = $self->first();
  $self->{first} = $old_first->next();
  $self->{last} = undef unless defined $self->{first};
  return $old_first->_delete_first();
}

=pod

=item unshift($value)

Adds a new node at the beginning of the list with the given value. Returns the
newly added node.

=cut

sub unshift ($self, $value) {
  return $self->_push($value) if $self->{reverse};
  return $self->_unshift($value);
}

=pod

=item push($value)

Adds a new node at the end of the list with the given value. Returns the
newly added node.

=cut

sub push ($self, $value) {
  return $self->_unshift($value) if $self->{reverse};
  return $self->_push($value);
}

=pod

=item shift()

Removes the first node of the list and returns its value. Returns B<undef> if
the list is empty. Note that the method can also return B<undef> if the first
node’s value is B<undef>

For convenience, C<pop()> can be used as a synonym of C<shift()>.

=cut

sub shift ($self) {
  return $self->_shift();
}

sub pop ($self) {
  return $self->_shift();
}

=pod

=item size()

Returns the number of nodes in the list.

=cut

sub size ($self) {
  return $self->{size};
}

=pod

=item empty()

Returns whether the list is empty.

=cut

sub empty ($self) {
  return $self->size() == 0;
}

=pod

=item values()

Returns all the values of the list, as a normal Perl list. This runs in linear
time with the size of the list.

=cut

sub values ($self) {
  return $self->size() unless wantarray;
  my @ret = (0) x $self->size();
  my $i = 0;
  my $cur = $self->first();
  while (defined $cur) {
    $ret[$i++] = $cur->value();
    $cur = $cur->next();
  }
  return @ret;
}

# Runs a consistency check of the list. Assumes that tests are running with
# Test::More.
sub _self_check ($self, $name) {
  eval { use Test2::Tools::Compare qw(is T D U); use Test2::Tools::Subtest };
  subtest_streamed $name => sub {
    my $s = $self->{size};
    is($s >= 0, T(), 'Size is non-negative');
    if ($s == 0) {
      is($self->{first}, U(), 'No first when size is 0');
      is($self->{last}, U(), 'No last when size is 0');
    } else {
      is($self->{first}, D(), 'Has first when size is not 0');
      is($self->{last}, D(), 'Has last when size is not 0');
      my $n = $self->{first};
      my $c = 0;
      while ($n) {
        $c++;
        is($n->{list} == $self, T(), 'Self pointer in node');
        if ($c < $s) {
          is($n->{next}, D(), 'Node has next element');
        } else {
          is($n->{next}, U(), 'Node has no next element');
          is($n == $self->{last}, T(), 'Correct last element');
        }
        $n = $n->{next};
      }
      is($c, $s, 'Correct node count');
    }
  };
}

# The destructor is not strictly needed because all the nodes don’t have cyclic
# references. But let’s keep it.
sub DESTROY ($self) {
  my $next = $self->{first};
  while (defined $next) {
    my $cur = $next;
    $next = $cur->{next};
    undef %{$cur};
  }
  return;
}

=pod

=back

=head1 SEE ALSO

L<DataStructure::DoubleList>

=head1 AUTHOR

Mathias Kende <mathias@cpan.org>

=head1 LICENCE

Copyright 2021 Mathias Kende

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
