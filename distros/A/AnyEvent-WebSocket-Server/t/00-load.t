use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::WebSocket::Server' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::WebSocket::Server $AnyEvent::WebSocket::Server::VERSION, Perl $], $^X" );
