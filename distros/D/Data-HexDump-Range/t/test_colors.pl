
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
	    ['magic cookie', 12, 'good'],
	    ['padding', 88, 'bad'],
	  ],
		
	  [
	    ['extra data', 12, 'green'],
	      [
	      ['footer', 7, 'bright_yellow on_red'],
	    ]
	  ],
	] ;
	
my $hdr = Data::HexDump::Range->new
			(
			COLOR_NAMES =>
				{
				ANSI =>
					{
					good => 'bright_yellow on_red',
					bad => 'bright_green on_red',
					},
				},
			
			) ;

my $data = 'A' . chr(5) . ('0123456789' x  100 ) ;
my $offset  = 0 ;

$offset = $hdr->gather($range, $data) ;
$offset = $hdr->gather($other_range, $data, $offset) ;

print $hdr->dump_gathered() ;

