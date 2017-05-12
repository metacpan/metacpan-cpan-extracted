#!perl -T
use Test::More tests => 2;
use App::Unix::RPasswd::Connection;

my $conn = App::Unix::RPasswd::Connection->new(
    user     => 'pedro',
    ssh_args => [ 'ssh', '-t' ]
);

isa_ok( $conn, 'App::Unix::RPasswd::Connection' );
can_ok( $conn, ( 'run', '_construct_cmd' ) );