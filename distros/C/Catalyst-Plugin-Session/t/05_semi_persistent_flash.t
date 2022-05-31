use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
};

use Test::More;

use lib "t/lib";

use MiniUA;

my $ua = MiniUA->new('FlashTestApp');

my $res;

# flash absent for initial request
$res = $ua->get( "http://localhost/first" );
ok +$res->is_success;
like +$res->content, qr{flash is not set}, "not set";

# present for 1st req.
$res = $ua->get( "http://localhost/second");
ok +$res->is_success;
like +$res->content, qr{flash set first time}, "set first";

# should be the same 2nd req.
$res = $ua->get( "http://localhost/third");
ok +$res->is_success;
like +$res->content, qr{flash set second time}, "set second";

# and the third request, flash->{is_set} has the same value as 2nd.
$res = $ua->get( "http://localhost/fourth");
ok +$res->is_success;
like +$res->content, qr{flash set 3rd time, same val as prev.}, "set third";

# and should be absent again for the 4th req.
$res = $ua->get( "http://localhost/fifth");
ok +$res->is_success;
like +$res->content, qr{flash is not}, "flash has gone";

done_testing;
