use strict;
use warnings;

use lib 't/lib';

my @dummys = ( 1, 1, 0, 0, 1 );

# the all `require` inside of `if` sholud NOT to be parsed

unless ( shift @dummys ) {
    require Module::Exists::Unexpected;    # braced
}

unless ( shift @dummys ) {    # comment
    require Module::Exists::Unexpected;    # double braced
}    # comment

unless ( shift @dummys ) {    # first
    unless ( shift @dummys ) {    # second
        unless ( shift @dummys ) {    # third
            require Module::Exists::Unexpected;    # triple braced
        }
    }
}

require Acme::BadExample;    # does not exist anywhere

