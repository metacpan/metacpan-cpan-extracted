use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':stream';

# randomly generated. DO NOT USE.
# for bad_* first or last nybble changed
my $key = pack('H*', '5631bcdeb02c2282f0ae7de62fd5bbe2ef90040e27592be927b6d7a3b027dde4');
my $bad_key = pack('H*', 'b631bcdeb02c2282f0ae7de62fd5bbe2ef90040e27592be927b6d7a3b027dde4');
my $nonce = pack('H*', 'f361eac627c100d660945d0c3539a6c0c7d2818c50db7563');
my $bad_nonce = pack('H*', 'f361eac627c100d660945d0c3539a6c0c7d2818c50db7569');

my $str = 'you step in the stream, but the water has moved on. 404 NOT FOUND.';

my $bytes = stream(32, $nonce, $key);
ok($bytes, "stream generated output");
is(length($bytes), 32, "stream generated correct length of output");

my $ct = stream_xor($str, $nonce, $key);
ok($ct, "stream_xor generated output");
is(length($ct), length($str), "stream_xor generated correct length output");

my $pt = stream_xor($ct, $nonce, $key);
is($pt, $str, "stream_xor roundtripped");
my $bad_pt = stream_xor($ct, $nonce, $bad_key);
isnt($bad_pt, $str, "stream_xor failed with bad key");
$bad_pt = stream_xor($ct, $bad_nonce, $key);
isnt($bad_pt, $str, "stream_xor failed with bad nonce");

done_testing();
