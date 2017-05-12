
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $hdr = Data::HexDump::Range
			->new
				(
				#~ DUMP_RANGE_DESCRIPTION => 1,
				#~ DUMP_ORIGINAL_RANGE_DESCRIPTION => 1,
				) ;

#~ print $hdr->dump([ ['range_1', 10, 'red'], ['range_2', 10] ], '0123456789' x 2, undef, 18) ;

my $data = '01234X6789' ;

#~ print $hdr->dump(['range_3', 1], $data, 5) ;
#~ print $hdr->dump([['range_4', 3]], $data, 7, 3) ;
#~ print $hdr->dump([['range_5', 3]], $data, 0, 3) ;
#~ print $hdr->dump([['range_6', 5]], $data, 0, 3) ;
#~ print $hdr->dump([['range_7', 5]], $data, 8, 3) ;

#~ print $hdr->dump([ ['range_8', 5], ['range_9', 5] ], $data, 0, 8) ;

#~ print $hdr->dump([ ['range_10', 5], ['range_11', 5] ], $data, -1, 8) ;

#~ print $hdr->dump([['range_12', 1]], $data, 15) ; # offset greater than size of data
#~ print $hdr->dump([['range_13', 2], ['range_12', 2]], $data, length($data) - 1) ;
#~ print $hdr->dump([['range_14', 10]], $data, 0, 0) ;
#~ print $hdr->dump([['range_15', 10]], $data, 0,  -1) ;
#~ print $hdr->dump([['range_16', 10]], $data, 9,  0) ;
print $hdr->dump([['range_17', 10]], $data, 9,  111111111) ;

