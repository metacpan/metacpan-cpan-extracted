use strict;
use warnings;

use lib 't/lib';

my @dummys = ( 0, 0, 0, 0, 0 );

# the all inside of 'if' nested sholud NOT to be parsed

if ( shift @dummys ) {
    require Require::With::If;    # braced
}

if ( shift @dummys ) {    # comment
    require Require::With::If::Commented;    # double braced
}    # comment

if ( shift @dummys ) {    # first
    if ( shift @dummys ) {    # second
        if ( shift @dummys ) {    # third
            require Require::With::Nested::If;    # triple braced
        }
    }
}

require Dummy;                                    # does not exist anywhere

exit;
