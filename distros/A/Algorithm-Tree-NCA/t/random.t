# -*- Mode: Perl -*-
# Copyright 2002 by Mats Kindahl. All rights reserved. 
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

package Node;

use fields qw(_children _number);
use strict;

my $Number = 0;

sub new ($@) {
    my($class,@children) = @_;
    my $self = { _children => [@children],
		 _number => ++$Number };
    bless $self,$class;
}

sub children {
    my($self) = @_;

    return @{$self->{_children}};
}

sub display {
    my($self,$indent) = @_;
    print STDERR ' ' x (2*$indent), "+ ", $self->{_number}, "\n";
    foreach my $c ($self->children()) {
	$c->display($indent+1);
    }
}

sub naive_nca ($$) {
    my($self,$a,$b) = @_;

    # This is one of the nodes that should give the NCA: return a
    # defined value
    if ($self == $a or $self == $b) {
	return $self;
    }

    my $result = undef;

    foreach my $c ($self->children()) {
	my $x = $c->naive_nca($a,$b);
	if (defined $x) {
	    if (defined $result) { 
		# We have two children that are defined: the NCA is $self
		$result = $self;
	    } else {
		# This node is either below or above the NCA: 
		# - we return the NCA, if we are above the NCA
		# - we return a defined value, if we are below the NCA
		$result = $x;
	    }
	} 
    }
    return $result;
}

package main;

# Testcase to test if the naive version and this implementation of NCA
# agree.

use Test;
my @cases;

BEGIN {
    @cases = ([4711, 10], [1919, 50], [1111, 57],
	      [1234, 11], [4321, 33], [2222, 113]);
    plan tests => 1+@cases, todo => [];
}

use Algorithm::Tree::NCA;
ok(1); # If we made it this far, we're ok.

sub make_tree {
    my($seed, $leaves) = @_;
    my @nodes;
    
    # Make $leaves nodes that will be leaves
    push(@nodes, new Node) for 1..$leaves;

    my @tree = @nodes;

    # Repeatedly merge two neighbours
    while (@tree > 1) {
	my $x = $seed % (@tree - 1);
	my $node = new Node($tree[$x],$tree[$x+1]);
	splice(@tree, $x, 2, $node);
	$seed = $x + 17;
    }

    return (@tree, [@nodes]);
}

sub nr { return $_[0]->{_number} }


#  print "Made a tree\n";
#  $root->display(0);

foreach my $a (@cases) {
    my($seed,$count) = @$a;
    my($root, $nodesref) = make_tree($seed, $count);
    my $nca = new Algorithm::Tree::NCA;
    $nca->preprocess($root);

    my $bad = 0;
    foreach my $x (@$nodesref) {
	foreach my $y (@$nodesref) {
	    my $z = $nca->nca($x,$y);
	    my $n = $root->naive_nca($x,$y);
	    ++$bad unless $z == $n;
	}
    }
    ok($bad,0);
}

