use Test::More tests => 11;
use strict;
use warnings;
use Crypt::Keyczar::Util qw(decode_json);

BEGIN { use_ok 'Crypt::Keyczar::Key' };

my $key;
$key = Crypt::Keyczar::Key->read_key('HMAC_SHA1', q|{"hmacKeyString": "nmDxqRHSKupvXqZky0N2g0n7HJZSYorokuRC4VDxAaU", "size": 128}|);
ok($key);
ok($key->get_bytes eq pack 'H*', '9e60f1a911d22aea6f5ea664cb43768349fb1c9652628ae892e442e150f101a5');
ok($key->hash eq pack 'H*', 'ff07fe34');
my $data = decode_json($key->to_string);
ok($data->{hmacKeyString} eq 'nmDxqRHSKupvXqZky0N2g0n7HJZSYorokuRC4VDxAaU');
ok($data->{size} == 128);

SKIP: {
    skip "SHA224 not supported", 5 if !Crypt::Keyczar::HmacEngine->is_supported('SHA224');
    $key = Crypt::Keyczar::Key->read_key('HMAC_SHA224', q|{"hmacKeyString": "nmDxqRHSKupvXqZky0N2g0n7HJZSYorokuRC4VDxAaU", "size": 128}|);
    ok($key);
    ok($key->get_bytes eq pack 'H*', '9e60f1a911d22aea6f5ea664cb43768349fb1c9652628ae892e442e150f101a5');
    ok($key->hash eq pack 'H*', 'ff07fe34');
    $data = decode_json($key->to_string);
    ok($data->{hmacKeyString} eq 'nmDxqRHSKupvXqZky0N2g0n7HJZSYorokuRC4VDxAaU');
    ok($data->{size} == 128);
}

