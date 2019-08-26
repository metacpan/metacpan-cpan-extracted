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

package Config::AST::Node::Value;
use parent 'Config::AST::Node';
use strict;
use warnings;

=head1 NAME

Config::AST::Node::Value - simple statement node

=head1 DESCRIPTION

Implements a simple statement node. Simple statement is always associated
with a value, hence the class name.    

=cut    

sub new {
    my $class = shift;
    local %_ = @_;
    my $v = delete $_{value};
    my $self = $class->SUPER::new(%_);
    $self->value($v);
    return $self;
}

=head1 METHODS

=head2 $node->value

Returns the value associated with the statement.

If value is a code reference, it is invoked without arguments, and its
return is used as value.    
    
If the value is a reference to a list or hash, the return depends on the
context. In scalar context, the reference itself is returned. In list
context, the array or hash is returned.

=cut    

sub value {
    my ($self, $val) = @_;

    if (defined($val)) {
	$self->{_value} = $val;
	return; # Avoid evaluatig value too early
    } else {
	$val = $self->{_value};
    }
    
    if (ref($val) eq 'CODE') {
	$val = &$val;
    }

    if (wantarray) {
	if (ref($val) eq 'ARRAY') {
	    return @$val
	} elsif (ref($val) eq 'HASH') {
	    return %$val
        }
    }
    
    return $val;
}

=head2 bool = $node->is_leaf

Returns false.

=cut    
    
sub is_leaf { 1 };

=head2 $s = $node->as_string

Returns the node value, converted to string.

=cut    

sub as_string {
    my $val = shift->value;
    if (ref($val) eq 'ARRAY') {
        return @$val ? $val : '';
    } elsif (ref($val) eq 'HASH') {
        return keys %$val ? $val : '';
    } else {
        return $val;
    }
}

=head2 $s = $node->as_number

Returns the node value, converted to number.

If the value is an array, returns number of elements in the array.
If the value is a hash, returns number of keys.
Otherwise, returns the value itself.

=cut    

sub as_number {
    my $val = shift->value;
    if (ref($val) eq 'ARRAY') {
        return scalar @$val;
    } elsif (ref($val) eq 'HASH') {
        return keys %$val;
    } else {
        return $val;
    }
}

=head1 CONTEXT-SENSITIVE COERCIONS

Depending on the context in which it is used, the B<Config::AST::Node::Value>
is coerced to the most appropriate data type.  For example, in the following
expression;

   if ($cf->getnode('offset') < 10) {
      ...
   }

the value will be coerced to a number prior to comparison.  This means that
in most cases you don't need to explicitly invoke the B<value> method.

=cut

use overload
    '""' => \&as_string,
    '0+' => \&as_number,
    '<=>' => sub {
	my ($self, $other, $swap) = @_;
        my $res = $self->as_number <=> $other;
        return $swap ? - $res : $res;
    },
    'cmp' => sub {
        my ($self, $other, $swap) = @_;
        my $res = $self->as_string cmp "$other";
        return $swap ? - $res : $res;
    },
    fallback => 1;
    

=head1 SEE ALSO

B<Config::AST>,    
B<Config::AST::Node>.

=cut    

1;
