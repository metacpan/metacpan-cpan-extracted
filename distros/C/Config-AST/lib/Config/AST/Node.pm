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

package Config::AST::Node;

use strict;
use warnings;
use parent 'Exporter';
use Text::Locus;
use Clone 'clone';

use Carp;

our %EXPORT_TAGS = ( 'sort' => [ qw(NO_SORT SORT_NATURAL SORT_PATH) ] );
our @EXPORT_OK = qw(NO_SORT SORT_NATURAL SORT_PATH);

=head1 NAME

Config::AST::Node - generic configuration syntax tree node

=head1 SYNOPSIS

use parent 'Config::AST::Node';
    
=head1 DESCRIPTION

This is an abstract class representing a node in the configuration parse
tree. A node can be either a non-leaf node, representing a I<section>, or
a leaf node, representing a I<simple statement>.

=head1 METHODS    

=head2 new(ARG => VAL, ...)

Creates new object. Recognized arguments are:

=over 4

=item B<clone =E<gt>> I<OBJ>

Clone object I<OBJ>, which must be an instance of B<Config::AST::Node>
or its derived class.

=item B<default =E<gt>> I<VAL>

Sets default value.

=item B<locus =E<gt>> I<LOC>

Sets the locus - an object of class B<Text::Locus>, which see.

=item B<file =E<gt>> I<NAME>    

Sets the file name.

=item B<order =E<gt>> I<N>

Sets ordinal number.

=back
    
=cut    
    
sub new {
    my $class = shift;
    local %_ = @_;
    my $v;
    my $self;
    if ($v = delete $_{clone}) {
	$self = Clone::clone($v);
    } else {
	$self = bless { }, $class;
    }
    if (defined($v = delete $_{default})) {
	$self->default($v);
    }
    if (defined($v = delete $_{locus})) {
	$self->locus($v);
    }

    if (defined($v = delete $_{file})) {
	$self->locus($v, delete $_{line} // 0);
    }
    if (defined($v = delete $_{order})) {
	$self->order($v);
    }
    croak "unrecognized arguments" if keys(%_);
    return $self;
}

=head2 $x = $node->locus;

Returns a locus associated with the node.
    
=head2 $node->locus($LOC)

=head2 $node->locus($FILE, $LINE)    

Associates a locus with the node. In the second form, a new locus object
is created for location I<$FILE>:I<$LINE>.
    
=cut

sub locus {
    my $self = shift;
    if (@_ == 1) {
	croak "bad argument type"
	    unless ref($_[0]) eq 'Text::Locus';
	$self->{_locus} = $_[0];
    } elsif (@_ == 2) {
	$self->{_locus} = new Text::Locus(@_);
    } elsif (@_) {
	croak "bad number of arguments";
    }
    return $self->{_locus} ||= new Text::Locus;
}

=head2 $x = $node->order

=head2 $node->order(I<$N>)

Returns or sets and returns ordinal number for the node.

=cut    
    
sub order {
    my ($self, $val) = @_;
    if (defined($val)) {
	$self->{_order} = $val;
    }
    return $self->{_order} // 0;
}

=head2 $x = $node->default

=head2 $node->default(I<$N>)

Returns or sets and returns default value for the node.

=cut    
    
sub default {
    my ($self, $val) = @_;
    if (defined($val)) {
	$self->{_default} = $val;
    }
    return $self->{_default};
}

=head2 $node->is_leaf

Returns true if node is a leaf node
    
=cut    

sub is_leaf { 0 }

=head2 $node->is_null

Returns true if node is a null node

=cut    

sub is_null { 0 }

=head2 $node->is_section

Returns true if node represents a section.

=cut    

sub is_section { 0 }

=head2 $node->is_value

Returns true if node represents a value (or statement).

=cut

sub is_value { shift->is_leaf }

use constant {
    NO_SORT => sub { @_ },
    SORT_NATURAL => sub {
	    sort { $a->[1]->order <=> $b->[1]->order } @_
    },
    SORT_PATH => sub {
	sort { join('.',@{$a->[0]}) cmp join('.', @{$b->[0]}) } @_
    }
};

=head2 @array = $cfg->flatten()

=head2 @array = $cfg->flatten(sort => $sort)    

Returns a I<flattened> representation of the configuration, as a
list of pairs B<[ $path, $value ]>, where B<$path> is a reference
to the variable pathname, and B<$value> is a
B<Config::AST::Node::Value> object.

The I<$sort> argument controls the ordering of the entries in the returned
B<@array>.  It is either a code reference suitable to pass to the Perl B<sort>
function, or one of the following constants:

=over 4

=item NO_SORT

Don't sort the array.  Statements will be placed in an apparently random
order.

=item SORT_NATURAL

Preserve relative positions of the statements.  Entries in the array will
be in the same order as they appeared in the configuration file.  This is
the default.

=item SORT_PATH

Sort by pathname.

=back

These constants are not exported by default.  You can either import the
ones you need, or use the B<:sort> keyword to import them all, e.g.:

    use Config::AST::Node qw(:sort);
    @array = $node->flatten(sort => SORT_PATH);
    
=cut

sub flatten {
    my $self = shift;
    local %_ = @_;
    my $sort = delete($_{sort}) || SORT_NATURAL;
    my @ar;
    my $i;
    
    croak "unrecognized keyword arguments: ". join(',', keys %_)
	if keys %_;

    push @ar, [ [], $self ];
    foreach my $elt (@ar) {
	next if $elt->[1]->is_value;
	while (my ($kw, $val) = each %{$elt->[1]->subtree}) {
	    push @ar, [ [@{$elt->[0]}, $kw], $val ];
	}
    }

    croak "sort must be a coderef"
	unless ref($sort) eq 'CODE';

    shift @ar; # toss off first entry
    return &{$sort}(grep { $_->[1]->is_value } @ar);
}       

=head2 $cfg->canonical(%args)

Returns the canonical string representation of the configuration node.
For value nodes, canonical representation is:

    QVAR=VALUE

where QVAR is fully qualified variable name, and VALUE is the corresponding
value.

For sections, canonical representation is a list of canonical representations
of the underlying nodes, delimited by newlines (or another character - see the
description of the B<delim> argument, below). The list is sorted by QVAR in
ascending lexicographical order.

B<%args> are zero or more of the following keywords:

=over 4

=item B<delim =E<gt> >I<STR>

Use I<STR> to delimit statements, instead of the newline.

=item B<locus =E<gt> 1>     

Prefix each statement with its location.

=back    
    
=cut

sub canonical {
    my $self = shift;
    local %_ = @_;
    my $delim;
    unless (defined($delim = delete $_{delim})) {
	$delim = "\n";
    }
    my $prloc = delete $_{locus};
    carp "unrecognized parameters: " . join(', ', keys(%_)) if (keys(%_));
    
    return join $delim, map {
		             ($prloc ? '[' . $_->[1]->locus . ']: ' : '')
				 . join('.', map {
				                 if (/[\.="]/) {
						     s/\"/\\"/;
						     '"'.$_.'"'
						 } else {
						     $_
						 }
					     } @{$_->[0]})
			     . "="
			     . Data::Dumper->new([scalar $_->[1]->value])
			                   ->Useqq(1)
					   ->Terse(1)
					   ->Indent(0)
					   ->Dump
    } $self->flatten(sort => SORT_PATH);
}

use overload
    bool => sub { 1 },
    '""' => sub { shift->as_string },
    eq => sub {
	my ($self,$other) = @_;
	return $self->as_string eq $other
    };
	
=head1 SEE ALSO

L<Config::AST>,    
L<Config::AST::Node::Null>,
L<Config::AST::Node::Value>,
L<Config::AST::Node::Section>.
    
=cut    

1;

	
