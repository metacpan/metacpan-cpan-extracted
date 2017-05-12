
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $range = # definition to re-use
	[
	    ['error', 88, undef, undef],
	    ['error'],
	] ;

my $hdr = Data::HexDump::Range->new() ;

my $data = 'A' . chr(5) . ('0123456789' x  100 ) ;
$hdr->gather($range, $data) ;

