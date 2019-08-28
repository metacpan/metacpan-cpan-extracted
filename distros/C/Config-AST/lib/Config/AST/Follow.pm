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

package Config::AST::Follow;
use Config::AST::Node;
use Config::AST::Node::Null;
use strict;
use warnings;
use Carp;

=head1 NAME

Config::AST::Follow - direct addressing engine

=head1 DESCRIPTION

This class implements direct node addressing in B<Config::AST>.
Objects of this class are created as

  $obj = Config::AST::Follow->new($node, $lexicon)

where B<$node> is the start node, and B<$lexicon> is the lexicon
corresponding to that node.  A B<Config::AST::Follow> object transparently
delegates its methods to the underlying I<$node>, provided that such
method is defined for I<$node>.  If it is not, it reproduces itself
with the new B<$node>, obtained as a result of the call to B<$node-E<gt>subtree>
with the method name as its argument.  If the result of the B<subtree> call
is a leaf node, it is returned verbatim.  The lexicon hash is consulted to
check if the requested node name is allowed or not.  If it is not, B<croak>
is called.  As a result, the following call:

  $obj->A->B->C

is equivalent to

  $node->getnode('X', 'Y', 'Z')

except that it will consult the lexicon to see if each name is allowed
within a particular section.

=head1 SEE ALSO

B<Config::AST>(3).

=cut

sub new {
    my ($class, $node, $lex) = @_;
    bless { _node => $node, _lex => $lex }, $class;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;

    $AUTOLOAD =~ s/(?:(.*)::)?(.+)//;
    my ($p, $m) = ($1, $2);

    if ($self->{_node}->can($m)) {
	return $self->{_node}->${\$m};
    }

    croak "Can't locate object method \"$m\" via package \"$p\""
	if @_;
    
    croak "Can't locate object method \"$m\" via package \"$p\" \
 (and no lexical info exists to descend to $m)"
	unless ref($self->{_lex}) eq 'HASH';
    
    (my $key = $m) =~ s/__/-/g;
    my $lex = $self->{_lex};
    if (ref($lex) eq 'HASH') {
	if (exists($lex->{$key})) {
	    $lex = $lex->{$key};
	} elsif (exists($lex->{'*'})) {
	    $lex = $lex->{'*'};
	} else {
	    $lex = undef;
	}
	croak "Can't locate object method \"$m\" via package \"$p\""
	    unless $lex;
    } else {
	croak "Can't locate object method \"$m\" via package \"$p\""
    }

    if (!ref($lex)) {
	if ($lex eq '*') {
	    $lex = { '*' => '*' };
	} else {
	    $lex = undef;
	}
    } elsif ($lex->{section}) {
	$lex = $lex->{section};
    } else {
	$lex = undef;
    }

    if (!$self->{_node}->is_null) {
	my $next = $self->{_node}->subtree($self->{_ci} ? lc($key) : $key)
	             // new Config::AST::Node::Null;
	return $next if $next->is_leaf || !$lex;
	$self->{_node} = $next;
    }
    
    $self->{_lex} = $lex;
    $self;
}

sub DESTROY { }

1;
