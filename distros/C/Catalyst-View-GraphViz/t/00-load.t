use Test::More tests => 1;

use lib "../lib";

BEGIN {
use_ok( 'Catalyst::View::GraphViz' );
}

diag( "Testing Catalyst::View::GraphViz $Catalyst::View::GraphViz::VERSION, Perl 5.008006");
