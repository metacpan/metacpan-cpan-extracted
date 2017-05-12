
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $data_range = # definition to re-use
	[
	  ['data header', 5, 'blue on_cyan'],
	  ['data', 20, 'blue on_bright_yellow'],
	] ;

my $structured_range = 
	[
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 88, 'yellow'],
	    $data_range, 
	  ],
		
	  [
	    ['extra data', 12, undef],
	      [
	      $data_range, 
	      ['footer', 4, 'bright_yellow on_red'],
	    ]
	  ],
	] ;
	
my $hdr = Data::HexDump::Range->new(ORIENTATION => 'vertical') ;

my $data = 'A' . chr(5) . '0123456789' x  128 ;

print $hdr->dump($structured_range, $data) ;

