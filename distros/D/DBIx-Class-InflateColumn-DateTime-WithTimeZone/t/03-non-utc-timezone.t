use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );

eval "use Test::NonUtcSchema";

my $err = $@;

like( $@, qr/non-UTC/, 'timestamp_source with non-UTC time zone gives error' );

done_testing;
