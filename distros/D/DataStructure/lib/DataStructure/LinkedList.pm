# A linked list data-structure.

package DataStructure::LinkedList;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

use DataStructure::LinkedList::Node;

=pod

=head1 NAME

DataStructure::LinkedList

=head1 SYNOPSIS

A linked list data-structure, written in pure Perl.

See also L<DataStructure::DoubleList> for a double-linked list version that
offers a richer interface.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

C<DataStructure::LinkedList->new()>

Creates an empty list.

=cut

sub new ($class) {
  return bless { size => 0, first => undef}, $class;
}

=pod

=head2 METHODS

All the functions below are class methods that should be called on a
B<DataStructure::LinkedList> object. Unless documented, they run in constant
time.

=head3 I<first()>

Returns the first L<DataStructure::LinkedList::Node> of the list, or B<undef> if
the list is empty.

=cut

sub first ($self) {
  return $self->{first};
}

=pod

=head3 I<unshift($value)>

Adds a new node at the beginning of the list with the given value. Returns the
newly added node.

For conveniance, I<push()> can be used as a synonym of I<unshift()>.

=cut

sub unshift ($self, $value) {
  my $new_node = DataStructure::LinkedList::Node->new($self, $self->{first}, $value);
  $self->{first} = $new_node;
  $self->{size}++;
  return $new_node;
}

sub push ($self, $value) {
  return $self->unshift($value);
}

=pod

=head3 I<shift()>

Removes the first node of the list and returns its value. Returns B<undef> if
the list is empty. Note that the method can also return B<undef> if the first
node’s value is B<undef>

For conveniance, I<pop()> can be used as a synonym of I<shift()>.

=cut

sub shift ($self) {
  return unless defined $self->{first};
  my $old_first = $self->first();
  $self->{first} = $old_first->next();
  return $old_first->_delete_first();
}

sub pop ($self) {
  $self->shift();
}

=pod

=head3 I<size()>

Returns the number of nodes in the list.

=cut

sub size ($self) {
  return $self->{size};
}

=pod

=head3 I<empty()>

Returns whether the list is empty.

=cut

sub empty ($self) {
  return $self->size() == 0;
}

=pod

=head3 I<values()>

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

=head1 SEE ALSO

L<DataStructure::DoubleList>

=cut

1;
