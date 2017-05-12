
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
	
#~ my $data_range = # definition to re-use
	#~ [
	  #~ ['data header', 5, 'blue on_cyan'],
	  #~ ['data', 20, 'blue on_bright_yellow'],
	#~ ] ;

#~ my $structured_range = 
	#~ [
	  #~ [
	    #~ ['magic cookie', 12, 'red'],
	    #~ ['padding', 88, 'yellow'],
	    #~ $data_range, 
	  #~ ],
		
	  #~ [
	    #~ ['extra data', 12, undef],
	      #~ [
	      #~ $data_range, 
	      #~ ['footer', 4, 'yellow on_red'],
	    #~ ]
	  #~ ],
	#~ ] ;
	
my $hdr = Data::HexDump::Range->new(ORIENTATION => 'vertical', FORMAT => 'ASCII' ) ;

my $data = 'A' . chr(5) . '0123456789' x  128 ;

my ($dump, $used_data)  = $hdr->get_dump_and_consumed_data_size($range, $data) ;
substr($data, 0, $used_data, '') ; # remove processed data part
print $dump ;

($dump, $used_data)  = $hdr->get_dump_and_consumed_data_size($other_range, $data) ;
substr($data, 0, $used_data, '') ; # remove processed data part
print $dump ;
