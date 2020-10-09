use strict;
use warnings;

use lib 't/lib';

my @dummys = ( 1, 0, 0, 0, 1, 1 );

if ( shift @dummys ) {    # first
    unless ( shift @dummys ) {    # second
        if ( shift @dummys ) {    # third
            require Require::With::Nested::If;    # triple braced
        }
    }
}

unless ( shift @dummys ) {    # first
    if ( shift @dummys ) {    # second
        unless ( shift @dummys ) {    # third
            require Require::With::Nested::If;    # triple braced
        }
    }
}

require Dummy;                                    # does not exist anywhere

exit;
