use 5.008;

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'DBD::Mock' );
}

if ( $ENV{REPORT_TEST_ENVIRONMENT} ) {
    warn "\n\nperl $] ($^O)\n\n";
}

done_testing();
