
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
sub my_parser 
	{
	my ($dumper, $data, $offset) = @_ ;
	
	my $first_byte = unpack ("x$offset C", $data) ;
	
	$offset < length($data)
		?  $first_byte == ord(0)
			? ['from "0"', 5, 'bright_yellow']
			: ['from "1"', 3, 'bright_green']
		: undef ;
	}

my $data = '01' x 20 ;
my $hdr = Data::HexDump::Range->new(ORIENTATION => 'hor') ;

print $hdr->dump(\&my_parser, $data) ;

