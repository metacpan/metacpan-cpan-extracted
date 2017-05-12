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

use strict;

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

use Algorithm::Tree::NCA;
use Benchmark;

my @seeds = (4711);

my %T = ('tarjan' => [], 'naive' => []);
my @sizes = map { 10 * $_ } (1..10);
my @counts = map {10 * $_ } (1..10);
my $Times = 20;

foreach my $seed (@seeds) {
    foreach my $size (@sizes) {
	foreach my $count (@counts) {
	    my($root, $nodesref) = make_tree($seed, $size);

	    {
		my $before = new Benchmark;
		for (1..$Times) {
		    my $nca = new Algorithm::Tree::NCA;
		    my $z;
		    my $i = 0;
		    my $cnt = $count;
		    $nca->preprocess($root);
		    while ($cnt-- > 0) {
			my $x = $nodesref->[$i];
			$i = ($i + 23) % (@$nodesref - 1);
			my $y = $nodesref->[$i];
			$z = $nca->nca($x,$y);
		    }
		}
		my $after = new Benchmark;

		$T{'tarjan'}->[$size][$count] 
		    = timediff($after,$before);
	    }

	    {
		my $before = new Benchmark;
		for (1..$Times) {
		    my $z;
		    my $i = 0;
		    my $cnt = $count;
		    while ($cnt-- > 0) {
			my $x = $nodesref->[$i];
			$i = ($i + 23) % (@$nodesref - 1);
			my $y = $nodesref->[$i];
			$z = $root->naive_nca($x,$y);
		    }
		}
		my $after = new Benchmark;

		$T{'naive'}->[$size][$count] 
		    = timediff($after,$before);
	    }
	}
    }
}

foreach my $s (@sizes) {
    foreach my $c (@counts) {
	printf "%5d%5d:\n", $s, $c;

	foreach my $m (keys %T) {
	    printf "\t%10s: %s\n", $m, timestr($T{$m}->[$s][$c]);
	}
    }
}
