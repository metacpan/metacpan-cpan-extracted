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

package Config::AST::Node::Null;
use parent 'Config::AST::Node';
use strict;
use warnings;
use Carp;

=head1 NAME

Config::AST::Node::Null - a null node    

=head1 DESCRIPTION

Implements null node - a node returned by direct retrieval if the requested
node is not present in the tree.    

In boolean context, null nodes evaluate to false.
    
=head1 METHODS

=head2 $node->is_null

Returns true.

=cut    
    
sub is_null { 1 }

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $key = $AUTOLOAD;
    $key =~ s/.*:://;
    if ($key =~ s/^([A-Z])(.*)/\l$1$2/) {
	return $self;
    }
    confess "Can't locate method $AUTOLOAD";
}

=head2 $node->as_string

Returns the string "(null)".

=cut    

sub as_string { '(null)' }

=head2 $node->value

Returns C<undef>.    

=cut

sub value { undef }

use overload
    '""' => \&value,
    bool => \&value,
    '0+' => \&value,
    fallback => 1;

=head1 SEE ALSO

B<Config::AST>,    
B<Config::AST::Node>.

=cut    

1;
