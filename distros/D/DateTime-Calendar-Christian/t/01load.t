use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

require_ok 'DateTime::Calendar::Christian'
    or BAIL_OUT;

done_testing;

# ex: set textwidth=72 :
