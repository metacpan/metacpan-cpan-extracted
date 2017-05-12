
use warnings ;
use strict ;
use Data::TreeDumper ;

my $s =
	{
	1 => 1,
	2 => 2,
	10 => 10,
	a => 'a',
	b => 'b', 
	aa => 'aa',
	c => 'c',
	reference => [],
	} ;

$s->{link} = $s->{reference} ;

$Data::TreeDumper::Displaycallerlocation++ ;

print DumpTree($s, 'test', USE_ASCII => 0) ;
PrintTree($s, 'test', USE_ASCII => 0) ;

PrintTree(27, 'test:') ;
print DumpTree(27, 'test:') ;

PrintTree(undef, 'test:') ;
print DumpTree(undef, 'test:') ;
