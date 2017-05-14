use t::lib::Eris::Test tests => 2;

my ( $server, $cv ) = new_server;
can_ok( $server, 'run' );
my $t; $t = AE::timer 0, 0, sub {
    undef $t;
    $cv->send('OK');
};

is( $server->run($cv), 'OK', 'Server closed' );
