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

package Config::AST::Node::Section;
use parent 'Config::AST::Node';
use strict;
use warnings;
use Carp;
use Config::AST::Node::Null;

=head1 NAME

Config::AST::Node::Section - Configuration section node.

=head1 DESCRIPTION

Nodes of this class represent configuration sections in the AST.    

=head1 METHODS
    
=head2 new(ROOT, ARG => VAL, ...)

Creates new section object. I<ROOT> is the root object of the tree or the
B<Config::AST> object. The I<ARG =E<gt> VAL> pairs are passed to
the parent class constructor (see B<Config::AST::Node>).

=cut

sub new {
    my $class = shift;
    my $root = shift or croak "mandatory parameter missing";
    local %_ = @_;
    my $self = $class->SUPER::new(%_);
    $self->{_subtree} = {};
    if ($root->isa('Config::AST')) {
	$root = $root->root;
    }
    $self->{_root} = $root;
    return $self;
}

sub is_leaf { 0 }
sub is_section { 1 }

sub root { shift->{_root} }

=head2 $t = $node->subtree

Returns tree containing all subordinate nodes of this node.

=head2 $t = $node->subtree($key)

Returns the subnode at I<$key> or B<undef> if there is no such subnode.

=head2 $t = $node->subtree($key => $value)

Creates new subnode with the given I<$key> and I<$value>.  Returns the
created node.

=cut    

sub subtree {
    my $self = shift;
    if (my $key = shift) {
	$key = $self->root->mangle_key($key);
	if (my $val = shift) {
	    $self->{_subtree}{$key} = $val;
	}
	return $self->{_subtree}{$key};
    }
    return $self->{_subtree};
}

=head2 @a = $node->keys;

Returns a list of names of all subordinate statements in this section.

=cut    

sub keys {
    my $self = shift;
    return keys %{$self->{_subtree}};
}

=head2 $bool = $node->has_key($str)

Returns true if statement with name B<$str> is present in the section
described by B<$node>.

=cut    

sub has_key {
    my ($self, $key) = @_;
    return $self->subtree($key);
}

=head2 $node->delete($name)

Deletes the node with name B<$name>. Returns the removed node, or C<undef>
if not found.    
    
=cut    

sub delete {
    my ($self, $key) = @_;
    delete $self->{_subtree}{$key};
}

=head2 $node->merge($other)

Merges the section B<$other> (a B<Config::AST::Node::Section>) to B<$node>.
    
=cut

sub merge {
    my ($self, $other) = @_;
    while (my ($k, $v) = each %{$other->subtree}) {
	if (my $old = $self->subtree($k)) {
	    if ($old->is_section) {
		$old->merge($v);
	    } elsif (ref($old->value) eq 'ARRAY') {
		push @{$old->value}, $v->value;
		$old->locus->union($v->locus);
	    } else {
		$old->value($v->value);
	    }
	} else {
	    $self->subtree($k => $old->clone);
	}
	$self->locus->union($v->locus);
    }
}

=head2 $h = $cfg->as_hash

=head2 $h = $cfg->as_hash($map)    

Returns parse tree converted to a hash reference. If B<$map> is supplied,
it must be a reference to a function. For each I<$key>/I<$value>
pair, this function will be called as:

    ($newkey, $newvalue) = &{$map}($what, $key, $value)

where B<$what> is C<section> or C<value>, depending on the type of the
hash entry being processed. Upon successful return, B<$newvalue> will be
inserted in the hash slot for the key B<$newkey>.

If B<$what> is C<section>, B<$value> is always a reference to an empty
hash (since the parse tree is traversed in pre-order fashion). In that
case, the B<$map> function is supposed to do whatever initialization that
is necessary for the new subtree and return as B<$newvalue> either B<$value>
itself, or a reference to a hash available inside the B<$value>. For
example:

    sub map {
        my ($what, $name, $val) = @_;
        if ($name eq 'section') {
            $val->{section} = {};
            $val = $val->{section};
        }
        ($name, $val);
    }
    
=cut

sub as_hash {
    my $self = shift;
    my $map = shift // sub { shift; @_ };
    my $hroot = {};
    my @ar;
    
    push @ar, [ '', $self, $hroot ];
    while (my $elt = shift @ar) {
	if ($elt->[1]->is_section) {
	    my $hr0 = {};
	    my ($name, $hr) = &{$map}('section', $elt->[0], $hr0);
	    $elt->[2]{$name} = $hr0;
	    while (my ($kw, $val) = each %{$elt->[1]->subtree}) {
		push @ar, [ $kw, $val, $hr ];
	    }
	} else {
	    my ($name, $value) = &{$map}('value', $elt->[0], scalar($elt->[1]->value));
	    $elt->[2]{$name} = $value;
	}
    }
    return $hroot->{''};
}

=head2 $s = $node->as_string

Returns the string "(section)".

=cut    

sub as_string { '(section)' }

=head1 SEE ALSO

L<Config::AST>,    
L<Config::AST::Node>.

=cut    

1;
