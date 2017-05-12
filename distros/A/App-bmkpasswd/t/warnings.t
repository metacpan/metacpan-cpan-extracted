use Test::More;
use strict; use warnings FATAL => 'all';

use App::bmkpasswd -all;

my $res;
$SIG{__WARN__} = sub { $res = shift };
passwdcmp('foo', 'bar');
like $res, qr/invalid hash/, 'invalid hash warns';

done_testing;
