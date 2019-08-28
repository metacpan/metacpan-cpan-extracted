# This file is part of Config::AST                            -*- perl -*-
# Copyright (C) 2017-2019 Sergey Poznyakoff <gray@gnu.org>
#
# Config::AST is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# Config::AST is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Config::AST.  If not, see <http://www.gnu.org/licenses/>.

package Config::AST::Root;
use strict;
use warnings;

=head1 NAME

Config::AST::Root - root of the abstract syntax tree

=head1 DESCRIPTION

An auxiliary class representing the root of the abstract syntax tree.
It is necessary because the tree itself forms a circular structure
(due to the B<root> attribute of B<Config::AST::Node::Section>). Without
this intermediate class (if B<root> pointed to B<Config::AST> itself),
the structure would have never been destroyed, because each element
would remain referenced at least once.

=head1 CONSTRUCTOR

=head2 $obj = new($ci)

I<$ci> is one to enable case-insensitive keyword lookup, and 0 otherwise.

=cut

sub new {
    my ($class, $ci) = @_;
    bless { _ci => $ci }, $class;
}

=head1 METHODS

=head2 $s = $r->mangle_key($name)

Converts the string I<$name> to a form suitable for lookups, in accordance
with the _ci attribute.

=cut

sub mangle_key {
    my ($self, $key) = @_;
    $self->{_ci} ? lc($key) : $key;
}

=head2 $r->reset

Destroys the underlying syntax tree.

=cut

sub reset { delete shift->{_tree} }


=head2 $t = $r->tree

Returns the root node of the tree, initializing it if necessary.

=cut

sub tree {
    my $self = shift;

    return $self->{_tree} //=
	        new Config::AST::Node::Section($self,
	                                       locus => new Text::Locus);
}

=head2 $bool = $r->empty

Returns true if the tree is empty.

=cut

sub empty {
    my $self = shift;
    return !($self->{_tree} && $self->{_tree}->keys > 0);
}

=head1 SEE ALSO

L<Config::AST>.

=cut

1;
