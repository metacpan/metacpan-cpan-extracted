use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

##
## unexpand
##

test
    option => "--unexpand",
    stdin  => <<END,
        
                
        90
1234    90
1234    1234    12
1234            12
一      二      三
一     二       三
一    二        三
END
    expect => <<END;
	
		
	90
1234	90
1234	1234	12
1234		12
一	二	三
一     二	三
一    二	三
END

done_testing;
