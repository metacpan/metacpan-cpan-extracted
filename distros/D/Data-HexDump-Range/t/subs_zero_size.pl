
use strict ;
use warnings ;

sub generate_user_info {my ($self, $data, $used_data, $size, $range) = @_ ;  "offset:$used_data left:$size"} ;

my $range = # definition to re-use
	[
	  [sub{'generated name'}, 5, 'blue on_cyan',  \&generate_user_info ],
	  ['size_zero', sub {0}, 'green', \&generate_user_info ],
	  ['generated_color', 20, sub{'red'}, \&generate_user_info ],
	  [sub{ ['generated', sub {5}, 'red on_bright_yellow', \&generate_user_info]} ],
	  ['end', 4],
	  ['size', 1, undef, 
		sub
			{
			my ($self, $data, $offset, $size, $range) = @_ ;
			
			$size = ord(substr($data, $offset, 1))  ;
			
			for($size)
				{
				$_ == 1 and do {return 'size is: S' } ;
				$_ == 2 and do {return  'size is: M'} ;
				$_ == 3 and do {return 'size is: L'} ;
				$_ == 4 and do {return  'size is: XL'} ;
				
				return 'Error in size range!' ;
				}
			}
	  ],
	
	  ['size', 1, undef, 
		sub
			{
			my ($self, $data, $offset, $size, $range) = @_ ;
			
			$size = ord(substr($data, $offset, 1))  ;
			print "$size ****\n" ;
			for($size)
				{
				$_ == 0x65 and do {return 'size is: S' } ;
				$_ == 2 and do {return  'size is: M'} ;
				$_ == 3 and do {return 'size is: L'} ;
				$_ == 4 and do {return  'size is: XL'} ;
				
				return 'Error in size range!' ;
				}
			}
	  ],
	
	] ;
			

