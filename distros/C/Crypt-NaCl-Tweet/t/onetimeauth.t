use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':onetimeauth';

# randomly generated. DO NOT USE.

my $str = 'hello';
my $key = pack('H*', '3623a3d9888c95b1855228963d246a3481b2f88e934cbef653769fb14b4374e4');
# changed first nybble to 0:
my $bad_key = pack('H*', '0623a3d9888c95b1855228963d246a3481b2f88e934cbef653769fb14b4374e4');

my $auth = onetimeauth($str, $key);
ok($auth, "onetimeauth generated authenticator");
is(length($auth), onetimeauth_BYTES, "onetimeauth correct length");

ok(onetimeauth_verify($auth, $str, $key), "onetimeauth_verify with correct key");
ok(!onetimeauth_verify($auth, $str, $bad_key), "onetimeauth_verify with incorrect key");

done_testing();
