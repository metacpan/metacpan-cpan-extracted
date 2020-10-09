use strict;
use warnings;

use lib 't/lib';

my @dummys = ( 1, 1, 0, 0, 1 );

# the all inside of 'if' nested sholud NOT to be parsed

unless ( shift @dummys ) {
    require Require::With::If;    # braced
}

unless ( shift @dummys ) {    # comment
    require Require::With::If::Commented;    # double braced
}    # comment

unless ( shift @dummys ) {    # first
    unless ( shift @dummys ) {    # second
        unless ( shift @dummys ) {    # third
            require Require::With::Nested::If;    # triple braced
        }
    }
}

require Dummy;                                    # does not exist anywhere

exit;
