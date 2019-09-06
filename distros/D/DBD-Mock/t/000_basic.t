use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBD::Mock' );
}

if ( $ENV{REPORT_TEST_ENVIRONMENT} ) {
    warn "\n\nperl $^V ($^O)\n\n";
}
