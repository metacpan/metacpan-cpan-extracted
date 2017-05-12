use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );

eval "use Test::MissingTzSchema";

my $err = $@;

like( $err, qr/could not find.* tz/ ,
  'timestamp_source with missing column gives error' )
  or diag $err;

done_testing;
