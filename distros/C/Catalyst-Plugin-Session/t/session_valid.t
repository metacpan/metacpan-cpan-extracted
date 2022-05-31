use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
};

use Test::More;

use lib "t/lib";

use MiniUA;

my $ua = MiniUA->new('SessionValid');

my $res;

$res = $ua->get( "http://localhost/" );
ok +$res->is_success, "initial get";
like +$res->content, qr{value set}, "page contains expected value";

sleep 2;

$res = $ua->get( "http://localhost/" );
ok +$res->is_success, "grab the page again, after the session has expired";
like +$res->content, qr{value set}, "page contains expected value";

done_testing;
