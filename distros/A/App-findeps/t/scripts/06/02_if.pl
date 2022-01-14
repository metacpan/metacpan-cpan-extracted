use strict;
use warnings;

use lib 't/lib';

my @dummys = ( 0, 0, 0, 0, 0, 0 );

# the all inside of 'if' nested sholud NOT to be parsed

if ( shift @dummys ) {
    require Module::Exists;    # braced
}

if ( shift @dummys ) {
    use Module::Exists;        # braced but used must be parsed
}

if ( shift @dummys ) {    # first
    if ( shift @dummys ) {    # second
        if ( shift @dummys ) {    # third
            require Module::Exists;    # triple braced
        }
    }
}

require Acme::BadExample;    # does not exist anywhere

