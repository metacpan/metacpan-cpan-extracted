#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Tree::Simple;
use Business::DK::Postalcode qw(get_all_postalcodes);

use constant VERBOSE => 0;

my $zipcodes = get_all_postalcodes();

my $tree = Tree::Simple->new();
my $oldtree = $tree;

my $j = 0;
foreach my $number (@{$zipcodes}) {
	$j++;
	print STDERR "\nWe have number: $number [$j]\n" if VERBOSE;
	my @digits = split(//, $number, 4);
	
	for(my $i = 0; $i < scalar(@digits); $i++) {

		print STDERR "We have digit: ".$digits[$i]."\n" if VERBOSE;;
		if ($i == 0) {
			print STDERR "We are resetting to oldtree: $i\n" if VERBOSE;
			$tree = $oldtree;
		}
		
 		my $subtree = Tree::Simple->new($digits[$i]);
 		
 		my @children = $tree->getAllChildren();
 		my $child = undef;
 		foreach my $c (@children) {
 			print STDERR "\$c: ".$c->getNodeValue()."\n" if VERBOSE;
 			if ($c->getNodeValue() == $subtree->getNodeValue()) {
				$child = $c;
				last;
 			}
 		}

  		if ($child) {
 			print STDERR "We are represented at $i with $digits[$i], we go to next\n" if VERBOSE;
		 	$tree = $child;
 		} else {
			print STDERR "We are adding child ".$subtree->getNodeValue."\n" if VERBOSE;
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