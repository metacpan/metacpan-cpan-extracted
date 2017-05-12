# -*- cperl -*-

use 5.010;
use English qw( -no_match_vars );
use Test::More tests => 1;

BEGIN {
    use_ok( 'Carp::Proxy' ) || print "Bail out!\n";
}

diag( <<"EOF" );


 Module      Carp::Proxy $Carp::Proxy::VERSION
 Perl        $]
 Executable  $EXECUTABLE_NAME

EOF
