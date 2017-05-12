# -*- Mode: Perl -*-
# Copyright 2002 by Mats Kindahl. All rights reserved. 
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

package Node;

use vars qw($Tree @Leader @Run @Magic);

sub new ($@) {
    my($class,@children) = @_;
    my $self = { _children => [@children] };
    bless $self,$class;
}

sub children {
    my($self) = @_;

    return @{$self->{_children}};
}

sub display {
    my($self,$indent) = @_;
    print ' ' x (2*$indent), $self->{_nca_number}, "\n";
    foreach my $c ($self->children()) {
	$c->display($c,$indent+1);
    }
}

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package main;

use Test;
BEGIN { plan tests => 5, todo => [] };
use Algorithm::Tree::NCA;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


my @Leader = (undef, 1, 2, 3, 2, 1, 6, 7, 1, 9, 10);
my @Run = (undef, 8, 4, 3, 4, 8, 6, 7, 8, 9, 10);
my @Magic = (undef, 8, 12, 13, 12, 8, 10, 9, 8, 9, 10);

my $Tree = Node->new(Node->new(Node->new(),
			       Node->new()),
		     Node->new(Node->new(),
			       Node->new(),
			       Node->new(Node->new(),
					 Node->new())));
ok(2);

use Data::Dumper;

my $nca = new Algorithm::Tree::NCA;
$nca->preprocess($Tree);

# Check that the leader is correct
{
    my $bad = 0;
    foreach my $d (@{$nca->{_data}}) {
	if (defined($d) 
	    && ($Leader[$d->{_number}] != $d->{_leader}->{_number})) 
	{
	    ++$bad;
	}
    }
    ok($bad == 0);
}

# Check that the run is correct
{
    my $bad = 0;
    foreach my $d (@{$nca->{_data}}) {
	if (defined $d
	    && $Run[$d->{_number}] != $d->{_run}) 
	{
	    ++$bad;
	}
    }
    ok($bad == 0);
}

# Check that the magic is correct
{
    my $bad = 0;
    foreach my $d (@{$nca->{_data}}) {
	if (defined $d
	    && $Magic[$d->{_number}] != $d->{_magic}) 
	{
	    ++$bad;
	}
    }
    ok($bad == 0);
}





