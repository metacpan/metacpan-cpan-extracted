# A double-linked list data-structure.

package DataStructure::DoubleList;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use DataStructure::DoubleList::Node;

use parent qw(DataStructure::Queue DataStructure::Stack);

=pod

=head1 NAME

DataStructure::DoubleList

=head1 SYNOPSIS

A double-linked list data-structure, written in pure Perl.

See also L<DataStructure::LinkedList> for a non double-linked list version.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

C<< DataStructure::DoubleList->new() >>

Creates an empty list.

=cut

sub new ($class) {
  return bless { size => 0, first => undef, last => undef}, $class;
}

=pod

=head2 METHODS

All the functions below are class methods that should be called on a
B<DataStructure::DoubleList> object. Unless documented otherwise, they run in
constant time.

=over 4

=item first()

Returns the first L<DataStructure::DoubleList::Node> of the list, or B<undef> if
the list is empty.

=cut

sub first ($self) {
  return $self->{first};
}

=pod

=item last()

Returns the last L<DataStructure::DoubleList::Node> of the list, or B<undef> if
the list is empty.

=cut

sub last ($self) {
  return $self->{last};
}

=pod

=item push($value)

Adds a new node at the end of the list with the given value. Returns the newly
added node.

=cut

sub push ($self, $value) {
  my $new_node = DataStructure::DoubleList::Node->new($self, $self->{last}, undef, $value);
  $self->{last}{next} = $new_node if defined $self->{last};
  $self->{last} = $new_node;
  $self->{first} = $new_node unless defined $self->{first};
  $self->{size}++;
  return $new_node;
}


=pod

=item unshift($value)

Adds a new node at the beginning of the list with the given value. Returns the
newly added node.

=cut

sub unshift ($self, $value) {
  my $new_node = DataStructure::DoubleList::Node->new($self, undef, $self->{first}, $value);
  $self->{first}{prev} = $new_node if defined $self->{first};
  $self->{first} = $new_node;
  $self->{last} = $new_node unless defined $self->{last};
  $self->{size}++;
  return $new_node;
}

=pod

=item pop()

Removes the last node of the list and returns its value. Returns B<undef> if the
list is empty. Note that the method can also return B<undef> if the last node’s
value is B<undef>

=cut

sub pop ($self) {
  return $self->{last}->delete if defined $self->{last};
  return;
}


=pod

=item shift()

Removes the first node of the list and returns its value. Returns B<undef> if
the list is empty. Note that the method can also return B<undef> if the first
node’s value is B<undef>

=cut

sub shift ($self) {
  return $self->{first}->delete if defined $self->{first};
  return;
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

L<DataStructure::LinkedList>, L<List::DoubleLinked>

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
