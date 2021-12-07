# Only used to define the version of the module and the core documentation.

package DataStructure;

use strict;
use warnings;
use utf8;
use feature ':5.24';

our $VERSION = '0.02';

=pod

=head1 NAME

DataStructure

=head1 SYNOPSIS

Collection of useful data-structures in pure Perl.

=head1 DESCRIPTION

This package is only here to define a common version for all the data-structure
in this distribution and to contain the core documentation. Please refer to the
documentation of the individual data-structure for more details.

=head1 DATA-STRUCTURE IMPLEMENTATIONS

These classes are actual implementations of data-structure. You should use them
to create objects but, in general, you should then only expect object of a
particular role (see below).

=over 4

=item L<DataStructure::DoubleList>

=item L<DataStructure::LinkedList>

=back

Note that you should never directly test the

=head1 ROLES

Roles, or data-structure interfaces, are

In DataStructure, the role are only implemented using normal Perl classes
inheritence. So you can test that an object has a particular role with
C<$obj->DOES('DataStructure::RoleName')> (you should use C<DOES> and not C<isa>
as the library might use another system in the future).

=over 4

=item DataStructure::Queue

Implemented by L<DataStructure::LinkedList> and L<DataStructure::DoubleList>

Has the following methods C<shift()>, C<push($value)>, C<values()>, C<empty()>,
C<size()>.

Nodes have the following methods: C<value()>.

Synonym: C<DataStructure::FIFO>.

=item DataStructure::Stack

Implemented by L<DataStructure::LinkedList> (with the C<reverse> option) and
L<DataStructure::DoubleList>.

Has the following methods C<first()>, C<push($value)>, C<pop()>, C<values()>,
C<empty()>, C<size()>.

Nodes have the following methods: C<value()>, C<insert_after($value)>, C<next()>.

Note that, without the C<reverse> option a L<DataStructure::LinkedList> can also
behave like a stack but you would need to use the less common C<shift> and
C<unshift> pair of methods. In that case, it will not have the C<Stack> role.

Synonym: C<DataStructure::LIFO>.

=item DataStructure::OrderedSet

Implemented by L<DataStructure::BTree>

Has the following methods C<insert($value)>, C<find($value)>,
C<delete($value | $node)>, C<values()>, C<empty()>, C<size()>.

=back

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
