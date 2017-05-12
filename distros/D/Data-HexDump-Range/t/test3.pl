
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $range = # definition to re-use
	[
	  ['data header', 5, 'blue on_cyan'],
	  ['data', 20, 'blue on_bright_yellow'],
	] ;
			
  my $other_range = 
	[
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 88, 'yellow'],
	  ],
		
	  [
	    ['extra data', 12, undef],
	      [
	      ['footer', 4, 'bright_yellow on_red'],
	    ]
	  ],
	] ;
	
my $hdr = Data::HexDump::Range->new(ORIENTATION => 'vertical') ;

my $data = 'A' . chr(5) . '0123456789' x  128 ;
my $offset  = 0 ;

$offset = $hdr->gather($range, $data) ;
$offset = $hdr->gather($other_range, $data, $offset) ;

print $hdr->dump_gathered() ;

