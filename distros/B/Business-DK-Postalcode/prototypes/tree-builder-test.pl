#!/usr/bin/perl -w

# $Id: tree-builder-test.pl,v 1.2 2006-09-05 18:19:18 jonasbn Exp $

use strict;
use Data::Dumper;
use Tree::Simple;

use constant DEBUG => 0;

my $tree = Tree::Simple->new();

my @data = qw(1234 1235 2345 2346);

my $oldtree = $tree;

my $j = 0;
foreach my $number (@data) {
	$j++;
	print STDERR "\nWe have number: $number [$j]\n" if DEBUG;
	my @digits = split(//, $number, 4);
	
	for(my $i = 0; $i < scalar(@digits); $i++) {

		print STDERR "We have digit: ".$digits[$i]."\n" if DEBUG;
		if ($i == 0) {
			print STDERR "We are resetting to oldtree: $i\n" if DEBUG;
			$tree = $oldtree;
		}
		
 		my $subtree = Tree::Simple->new($digits[$i]);
 		
 		my @children = $tree->getAllChildren();
 		my $child = undef;
 		foreach my $c (@children) {
 			print STDERR "\$c: ".$c->getNodeValue()."\n" if DEBUG;
 			if ($c->getNodeValue() == $subtree->getNodeValue()) {
				$child = $c;
				last;
 			}
 		}

  		if ($child) {
 			print STDERR "We are represented at $i with $digits[$i], we go to next\n" if DEBUG;
		 	$tree = $child;
 		} else {
			print STDERR "We are adding child ".$subtree->getNodeValue."\n" if DEBUG;
			$tree->addChild($subtree);
		 	$tree = $subtree;
 		}
	}
}
$tree = $oldtree;

$tree->traverse(sub {
	  my ($_tree) = @_;
	  print (("->" x $_tree->getDepth()), $_tree->getNodeValue(), "\n");
});
