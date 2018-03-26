use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 2;
 
BEGIN {
    use_ok('AnyEvent::Connector');
    use_ok('AnyEvent::Connector::Proxy::http');
}
 
diag( "Testing AnyEvent::Connector $AnyEvent::Connector::VERSION, Perl $], $^X" );
