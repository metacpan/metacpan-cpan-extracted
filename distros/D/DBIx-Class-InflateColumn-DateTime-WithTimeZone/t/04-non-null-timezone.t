use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );

eval "use Test::NonNullTzSchema";

# FIXME - better verification of error message
isnt( $@, undef, 'nullable datetime with non-null timezone gives error' );

done_testing;
