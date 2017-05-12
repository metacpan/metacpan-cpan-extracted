#!perl -w

use strict;
use B::Foreach::Iterator;

for my $key(foo => 10, bar => 20, baz => 30){
	printf "%s => %s\n", $key => iter->next;
}
