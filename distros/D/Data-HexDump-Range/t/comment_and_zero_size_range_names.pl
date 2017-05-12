
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
  my $range_defintion_with_comments = 
	[
	  ["very long comment text\nwith new line", '#', 'white on_red'],
	  ['magic cookie', 12, 'red'],
	  ['padding', 88, 'yellow'],
	    
	  [
	    ['comment two', '#'],
	    ['data header', 5, 'blue on_yellow'],
	    ['zero size', 0, 'black on_green'],
	    ['data', 80, 'blue on_bright_white'],
	  ],
	] ;
	
my $hdr = Data::HexDump::Range->new(ORIENTATION => 'ver') ;
print $hdr->dump($range_defintion_with_comments, '0123456789' x 20) ;

print "\n\n" ;
my $hdr2 = Data::HexDump::Range->new(ORIENTATION => 'hor') ;
print $hdr2->dump($range_defintion_with_comments, '0123456789' x 20) ;

