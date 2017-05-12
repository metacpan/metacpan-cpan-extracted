package test ;

use strict ;
use warnings ;

use Data::TreeDumper ;

sub main
{
my ($arguments) = @_ ;

print DumpTree $arguments, "In test module\n" ;
}

1 ;