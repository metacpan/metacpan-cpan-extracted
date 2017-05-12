use strict;
use warnings;

use Test::More;

# ABSTRACT: basics of _to_fun

use Call::From qw();
*_to_fun = \&Call::From::_to_fun;

is( _to_fun( \&_to_fun ), \&_to_fun, "Function references preserved" );
is( eval { ref _to_fun("Unknown") },
    undef, "Unknown functions can't be resolved" );
is( eval { ref _to_fun("::Unknown") },
    undef, "Unknown functions can't be resolved" );
is( _to_fun("main::_to_fun"),
    \&_to_fun, "Fully qualified functions can be resolved" );
is( _to_fun("Call::From::_to_fun"),
    \&_to_fun, "Fully qualified functions can be resolved" );
is( eval { _to_fun(undef) }, undef, "Undef is no function" );
is( eval { _to_fun("Unknown::") },
    undef, q[no-length function names are invalid] );

done_testing;

