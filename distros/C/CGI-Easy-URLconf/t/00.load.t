use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'CGI::Easy::URLconf' ) or BAIL_OUT('unable to load module') }

diag( "Testing CGI::Easy::URLconf $CGI::Easy::URLconf::VERSION, Perl $], $^X" );
