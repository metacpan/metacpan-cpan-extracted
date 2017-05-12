package Algorithm::AhoCorasick::SearchMachine;

use strict;
use warnings;

sub new {
    my $class = shift;

    if (!@_) {
	die "no keywords";
    }

    my %keywords;
    foreach (@_) {
	if (!defined($_) || ($_ eq '')) {
	    die "empty keyword";
	}

	$keywords{$_} = 1;
    }

    my $self = { keywords => [ keys %keywords ] };
    bless $self, $class;
    $self->_build_tree();
    return $self;
}

sub _build_tree {
    my $self = shift;

    $self->{root} = Algorithm::AhoCorasick::Node->new();

    # build transition links
    foreach my $p (@{$self->{keywords}}) {
	my $nd = $self->{root};
	foreach my $c (split //, $p) {
	    my $ndNew = $nd->get_transition($c);
	    if (!$ndNew) {
		$ndNew = Algorithm::AhoCorasick::Node->new(parent => $nd, char => $c);
		$nd->add_transition($ndNew);
	    }

	    $nd = $ndNew;
	}

	$nd->add_result($p);
    }

    # build failure links
    my @nodes;
    foreach my $nd ($self->{root}->transitions) {
	$nd->failure($self->{root});
	push @nodes, $nd->transitions;
    }

    while (@nodes) {
	my @newNodes;

	foreach my $nd (@nodes) {
	    my $r = $nd->parent->failure;
	    my $c = $nd->char;

	    while ($r && !($r->get_transition($c))) {
		$r = $r->failure;
	    }

	    if (!$r) {
		$nd->failure($self->{root});
	    } else {
		my $tc = $r->get_transition($c);
		$nd->failure($tc);

		foreach my $result ($tc->results) {
		    $nd->add_result($result);
		}
	    }

	    push @newNodes, $nd->transitions;
	}

	@nodes = @newNodes;
    }

    $self->{root}->failure($self->{root});
    $self->{state} = $self->{root};
}

sub feed {
    my ($self, $text, $callback) = @_;

    my $index = 0;
    my $l = length($text);
    while ($index < $l) {
	my $trans = undef;
	while (1) {
	    $trans = $self->{state}->get_transition(substr($text, $index, 1));
	    last if ($self->{state} == $self->{root}) || $trans;
	    $self->{state} = $self->{state}->failure;
	}

	if ($trans) {
	    $self->{state} = $trans;
	}

	foreach my $found ($self->{state}->results) {
	    my $rv = &$callback($index - length($found) + 1, $found);
	    if ($rv) {
		return $rv;
	    }
	}

	++$index;
    }

    return undef;
}

package Algorithm::AhoCorasick::Node;

use strict;
use warnings;
use Scalar::Util qw(weaken);

sub new {
    my $class = shift;

    my $self = { @_ };
    $self->{results} = { };
    $self->{transitions} = { };
    weaken $self->{parent} if $self->{parent};
    return bless $self, $class;
}

sub char {
    my $self = shift;

    if (!exists($self->{char})) {
	die "root node has no character";
    }

    return $self->{char};
}

sub parent {
    my $self = shift;

    if (!exists($self->{parent})) {
	die "root node has no parent";
    }

    return $self->{parent};
}

sub failure {
    my $self = shift;

    if (@_) {
        $self->{failure} = $_[0];
        weaken $self->{failure};
    }

    return $self->{failure};
}

# Returns transition to the specified character, or undef.
sub get_transition {
    my ($self, $c) = @_;

    return $self->{transitions}->{$c};
}

# Returns a list of descendant nodes.
sub transitions {
    my $self = shift;

    return values %{$self->{transitions}};
}

# Returns a list of patterns ending in this node.
sub results {
    my $self = shift;

    return keys %{$self->{results}};
}

# Adds pattern ending in this node.
sub add_result {
    my ($self, $res) = @_;

    $self->{results}->{$res} = 1;
}

# Adds transition node.
sub add_transition {
    my ($self, $node) = @_;

    $self->{transitions}->{$node->char} = $node;
}

1;

__END__

=head1 NAME

Algorithm::AhoCorasick::SearchMachine - implementation and low-level interface of Algorithm::AhoCorasick

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 use Algorithm::AhoCorasick::SearchMachine;

 sub callback {
     my ($pos, $keyword) = @_;

     ...

     return undef;
 }

 $machine = Algorithm::AhoCorasick::SearchMachine->new(@keywords);

 while (<STDIN>) {
     $machine->feed($_, \&callback);
 }

=head1 METHODS

=head2 new

The constructor. Takes the list of keywords as parameters (there must
be at least one, and the constructor dies if they contain an empty
string).

=head2 feed

Feeds input to the state machine. First (after the instance) argument
of this method is the input text (which can be empty, in which case
the method doesn't do anything), second argument is the callback
invoked on each match. C<feed> calls the callback with 2 arguments:
the position and the matched keyword. The callback can stop further
search by returning a true value, which C<feed> returns. If the search
wasn't stopped, C<feed> returns undef, and can then be called with
another chunk of input text to continue the search (matching all
keywords, even those spanning multiple chunks). Note that when the
callback stops the search, this scenario doesn't work (because the
state machine gets out of sync); C<feed> should not be called again on
the same instance after the callback returned true. Also note that the
position passed to the callback is relative to the current input text
chunk; it is negative for keywords spanning multiple chunks.

=head1 AUTHOR

Vaclav Barta, C<< <vbar@comp.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Vaclav Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

