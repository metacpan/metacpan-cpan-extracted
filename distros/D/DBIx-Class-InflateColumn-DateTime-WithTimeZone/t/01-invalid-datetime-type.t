use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );

eval "use Test::NonDateTimeSchema";

my $err = $@;

like( $err, qr/requires datetime data_type/,
  'timestamp_source on non-datetime column gives error' );

done_testing;
