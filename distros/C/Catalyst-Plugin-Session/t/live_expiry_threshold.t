use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
};

use Test::More;

use lib "t/lib";

use MiniUA;

my $ua = MiniUA->new('SessionExpiry');

my $res = $ua->get( "http://localhost/session_data_expires" );
ok($res->is_success, "session_data_expires");

my $expiry = $res->decoded_content + 0;

$res = $ua->get( "http://localhost/session_expires" );
ok($res->is_success, "session_expires");
is($res->decoded_content, $expiry, "session_expires == session_data_expires");

sleep(1);

$res = $ua->get( "http://localhost/session_data_expires" );
ok($res->is_success, "session_data_expires");

is($res->decoded_content, $expiry, "expiration not updated");

$res = $ua->get( "http://localhost/session_expires" );
ok($res->is_success, "session_expires");
is($res->decoded_content, $expiry, "session_expires == session_data_expires");

#

$res = $ua->get( "http://localhost/update_session" );
ok($res->is_success, "update_session");

$res = $ua->get( "http://localhost/session_data_expires" );
ok($res->is_success, "session_data_expires");

my $updated = $res->decoded_content + 0;
ok($updated > $expiry, "expiration updated");

$expiry = $updated;

$res = $ua->get( "http://localhost/session_data_expires" );
ok($res->is_success, "session_data_expires");

is($res->decoded_content, $expiry, "expiration not updated");

$res = $ua->get( "http://localhost/session_expires" );
ok($res->is_success, "session_expires");
is($res->decoded_content, $expiry, "session_expires == session_data_expires");

sleep(10);

$res = $ua->get( "http://localhost/session_data_expires" );
ok($res->is_success, "session_data_expires");

$updated = $res->decoded_content + 0;
ok($updated > $expiry, "expiration updated");

$res = $ua->get( "http://localhost/session_expires" );
ok($res->is_success, "session_expires");
is($res->decoded_content, $updated, "session_expires == session_data_expires");

done_testing;
