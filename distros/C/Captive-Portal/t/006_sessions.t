use strict;
use warnings;

use Test::More;

use_ok('Captive::Portal');

my ( $capo, $session, $ip, $mac, );

ok( $capo = Captive::Portal->new( cfg_file => 't/etc/ok.pl' ),
    'successfull parse t/etc/ok.pl' );

$capo->clear_sessions_from_disk;

$session = _mk_session();
$ip     = $session->{IP};

my %lock_options = (
    key      => $ip,
    blocking => 0,
    shared   => 0,
);

{
    my $lock_handle;
    ok( $lock_handle = $capo->get_session_lock_handle(%lock_options),
        'get session lock handle' );
    is( $capo->read_session_handle($lock_handle),
        undef, 'read empty session' );
    ok( $capo->write_session_handle( $lock_handle, $session ),
        'set session' );
    is_deeply( $capo->read_session_handle($lock_handle),
        $session, 'check session' );
    ok( $capo->write_session_handle( $lock_handle, $session ),
        'set same session again' );
    is_deeply( $capo->read_session_handle($lock_handle),
        $session, 'check session again' );
}

ok( $capo->clear_sessions_from_disk, 'cleared all sessions' ); 
is( $capo->list_sessions_from_disk, 0, 'listed 0 sessions' );

foreach my $i (1 .. 50) {
    my $session = _mk_session();
    my $ip     = $session->{IP};

    my %lock_options = (
	key      => $ip,
	blocking => 0,
	shared   => 0,
    );

    my $lock_handle = $capo->get_session_lock_handle(%lock_options);
}

is( $capo->list_sessions_from_disk, 50, 'created/listed 50 sessions' );
ok( $capo->clear_sessions_from_disk, 'cleared all sessions' );
is( $capo->list_sessions_from_disk, 0, 'listed 0 sessions' );

done_testing(13);

sub _mk_session {
    my $subnet = int( rand(256) );
    my $host   = int( rand(256) );
    my $byte   = unpack( 'H2', int( rand(256) ) );

    my $ip  = "10.10.$subnet.$host";
    my $mac = "00:01:02:03:04:$byte";

    my $session = {
        IP            => $ip,
        MAC           => $mac,
        STATE         => 'active',
        USERNAME      => 'test',
        USER_AGENT    => 'test',
    };

    return $session;
}

