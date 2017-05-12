# -*- Mode: Perl -*-
# Copyright 2002 by Mats Kindahl. All rights reserved. 
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

package Node;

sub new ($@) {
    my($class,@children) = @_;
    my $self = { _children => [@children] };
    bless $self,$class;
}

sub children {
    my($self) = @_;

    return @{$self->{_children}};
}

sub make_preorder_list ($$) {
    my($self,$listref) = @_;

    push(@$listref, $self);
    foreach my $c ($self->children()) {
	$c->make_preorder_list($listref);
    }
}


sub display {
    my($self,$indent) = @_;
    print ' ' x (2*$indent), $self->{_nca_number}, "\n";
    foreach my $c ($self->children()) {
	$c->display($indent+1);
    }
}

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package main;

use Test;
BEGIN { plan tests => 4, todo => [] };

use Algorithm::Tree::NCA;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $Tree = Node->new(Node->new(Node->new(),
			       Node->new()),
		     Node->new(Node->new(),
			       Node->new(),
			       Node->new(Node->new(),
					 Node->new())));

# Matrix with precomputed values of the NCA for each pair of nodes in
# the tree above. Observe that node number 0 is never used.
my $NCA = [[(undef) x 11],
           [undef, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  # Node 1
           [undef, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1],  # Node 2
           [undef, 1, 2, 3, 2, 1, 1, 1, 1, 1, 1],  # Node 3
           [undef, 1, 2, 2, 4, 1, 1, 1, 1, 1, 1],  # Node 4
           [undef, 1, 1, 1, 1, 5, 5, 5, 5, 5, 5],  # Node 5
           [undef, 1, 1, 1, 1, 5, 6, 5, 5, 5, 5],  # Node 6
           [undef, 1, 1, 1, 1, 5, 5, 7, 5, 5, 5],  # Node 7
           [undef, 1, 1, 1, 1, 5, 5, 5, 8, 8, 8],  # Node 8
           [undef, 1, 1, 1, 1, 5, 5, 5, 8, 9, 8],  # Node 9
           [undef, 1, 1, 1, 1, 5, 5, 5, 8, 8,10]]; # Node 10
ok(1);

{
    my $nca = new Algorithm::Tree::NCA;
    $nca->preprocess($Tree);

    my $bad = 0;
    my @Nodes;
    $Tree->make_preorder_list(\@Nodes);

    foreach my $x (@Nodes) {
	foreach my $y (@Nodes) {
	    my $xn = $nca->_data($x)->{_number};
	    my $yn = $nca->_data($y)->{_number};
	    my $p = $nca->nca($x,$y);
	    my $pn = $nca->_data($p)->{_number};
	    if ($NCA->[$xn]->[$yn] != $pn) {
		++$bad;
	    }
	}
    }
    ok($bad,0,"Failed $bad cases");
}

{
    my $nca = new Algorithm::Tree::NCA
	-tree => $Tree;

    my $bad = 0;
    my @Nodes;
    $Tree->make_preorder_list(\@Nodes);

    foreach my $x (@Nodes) {
	foreach my $y (@Nodes) {
	    my $xn = $nca->_data($x)->{_number};
	    my $yn = $nca->_data($y)->{_number};
	    my $p = $nca->nca($x,$y);
	    my $pn = $nca->_data($p)->{_number};
	    if ($NCA->[$xn]->[$yn] != $pn) {
		++$bad;
	    }
	}
    }
    ok($bad,0,"Failed $bad cases");
}
