
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
sub generate_user_info {my ($data, $used_data, $size, $range) = @_ ;  "offset:$used_data left:$size"} ;

#~ my $range = 'a,b4   :b,b3   :data,4 :c,b9  :d,b3  :e,x4b5 :the end,8' ;
my $range = 'data,4   :X1x1b1,X1x1b1 :X3x8b4,X3x8b4  :X4b8,X4b8, :X1x0b8,X1x0b8   :the end,8' ;
			
my $hdr = Data::HexDump::Range->new
			(
			DISPLAY_ZERO_SIZE_RANGE => 10, DISPLAY_ZERO_SIZE_RANGE_WARNING => 10,
			DISPLAY_USER_INFORMATION => 1,
			ORIENTATION => 'vertical',
			DISPLAY_COLUMN_NAMES => 1,
			#~ DUMP_RANGE_DESCRIPTION => 1,
			#~ BIT_ZERO_ON_LEFT => 1,
			) ;

my $data = 'A' . chr(5) . ('0123456789' x  100 ) ;

$hdr->gather($range, $data) ;

print $hdr->dump_gathered() ;

