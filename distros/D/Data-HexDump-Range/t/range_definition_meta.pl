
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
	    ['padding bitfield', 'x25b3'],
	    $data_range, 
	      [
		 ['bf', 'b4' ],
		 ['bf', 'x4b4'],
	      ],
	  ],
             ['other zero size', 0],		
	  [
	    ['extra data', 8, undef],
	      [
	      $data_range, 
	      ['footer', 4, 'bright_yellow on_red'],
	    ]
	  ],
	] ;
	
my $string_description = 'data,1 :x,3:DATA,4,, comment:c,b49:d,x49b3 :e,x4b5,, comment     :the end,8:x,b3:data,47,,comment:v,x90b8' ;

my $index = 0 ;
sub my_parser 
	{
	my ($dumper, $data, $offset) = @_ ;
	
	my $first_byte = unpack ("x$offset C", $data) ;
	
	$index++ ;
	$index == 1 
		? $structured_range
		: $index == 2
			? $string_description
			: undef
	}

my $index_2 = 0 ;
sub my_meta_parser 
	{
	my ($dumper, $data, $offset) = @_ ;
	
	my $first_byte = unpack ("x$offset C", $data) ;
	
	$index_2++ ;
	$index_2 == 1 
		? 'meta1,1'
		: $index_2 == 2
			? \&my_parser
			: undef
	}


\&my_meta_parser ;
