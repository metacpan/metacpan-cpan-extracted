#!perl -w

use strict;
use B::Foreach::Iterator;

print "(1)\n";
for my $i(0 .. 5){
	print $i, "\n"; # => 0, 2, 4

	iter->next;
}

print "(2)\n";
for my $i(0 .. 5){
	print iter->next, "\n"; # => 1, 3, 5
}
