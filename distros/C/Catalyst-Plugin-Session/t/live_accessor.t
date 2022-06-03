use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Authentication'          => '0',
  'Catalyst::Plugin::Session::State::Cookie'  => '0.03',
};

use Test::More;

use lib "t/lib";

use MiniUA;

my $ua = MiniUA->new('SessionTestApp');

my $res = $ua->get( '/accessor_test');
ok +$res->is_success, 'Set session vars okay';

like +$res->content, qr{two: 2}, 'k/v list setter works okay';

like +$res->content, qr{four: 4}, 'hashref setter works okay';

like +$res->content, qr{five: 5}, 'direct access works okay';

done_testing;
