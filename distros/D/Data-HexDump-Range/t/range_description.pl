
use strict ;
use warnings ;

my $data_range = # definition to re-use
	[
	  ['data header', 5, 'blue on_cyan'],
	  ['data', 20, 'blue on_bright_yellow'],
	] ;

my $structured_range = 
	[
	    ['zero size', 0],
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 32, 'yellow'],
	    $data_range, 
	  ],
             ['other zero size', 0],		
	  [
	    ['extra data', 18, undef],
	      [
	      $data_range, 
	      ['footer', 4, 'bright_yellow on_red'],
	    ]
	  ],
	] ;
	
$structured_range ;
