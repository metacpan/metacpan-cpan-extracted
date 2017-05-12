use warnings; use strict;
use Test::More tests => 16;
use Test::Fatal;

use lib '.';
use t::Ultra;
use Date::Parse;
use Scalar::Util qw<looks_like_number>;
use Bb::Collaborate::Ultra;
use Bb::Collaborate::Ultra::Session;

SKIP: {
      diag( "Testing Bb::Collaborate::Ultra $Bb::Collaborate::Ultra::VERSION, Perl $], $^X" );
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 16
	unless $connection;

    ok $connection->issuer, 'issuer';
    ok $connection->secret, 'secret';
    ok $connection->host, 'host';

    is exception { $connection->connect; }, undef, "connection lives";

    my $auth = $connection->auth;
    isa_ok $auth, 'Bb::Collaborate::Ultra::Connection::Token', 'auth';
    my $leased = $auth->_leased;
    ok $leased, '_leased';

    my $t = time();
    ok $leased > $t - 60 && $leased <= $t + 60, '_leased'
	or diag "time:$t _leased:$leased";

    ok $auth->access_token, 'access_token';
    my $expires = $auth->expires_in;
    ok $expires, 'expires_in';
    ok $expires > 0 && $expires <= 1000, 'expires_in'
	or diag "expires: $expires";

    my $start = $t + 300;
    my $end = $start + 1800;

    my $session = Bb::Collaborate::Ultra::Session->post($connection, {
	name => 'Test Session',
	startTime => $start,
	endTime   => $end,
    });
    my $session_id = $session->id;
    ok $session_id, 'got session_id';
    ok $session->created, "session creation";
    ok looks_like_number $session->created, "created data-type"
	or diag "created: " .  $session->created;

    $session = undef;

    $session = Bb::Collaborate::Ultra::Session->get(
    	     $connection, { id => $session_id, }
	);

    ok $session->created, "session creation";
    ok looks_like_number $session->created, "created data-type"
	or diag "created: " .  $session->created;

    is exception {
	$session->delete;
    }, undef, "session deletion lives";
}

done_testing;
