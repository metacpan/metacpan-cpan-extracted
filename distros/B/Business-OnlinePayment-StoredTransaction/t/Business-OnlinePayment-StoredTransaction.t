# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-OnlinePayment-StoredTransaction.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('Business::OnlinePayment') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


ok(my $transaction = new Business::OnlinePayment('StoredTransaction'), 
    'new StoredTransaction object');

my $cardnumber = '1234123412341238';
ok($transaction->content(
                        type       => 'Visa',
                        amount     => '49.95',
                        cardnumber => $cardnumber,
                        expiration => '0100',
                        action     => 'normal authorization',
                        name       => 'John Q Doe',
                        password   => '-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAOoKKH0CZm6sWHGg4SygikvvAecDS+Lx6ilUZ8mIVJeV2d6YjEJRjy12
TSFdJTC0SiBDbJ4UHz5ayXhLShK0VvaQY+sfZwMX1SNZNYUyO8T7gY7QCzOrcSTS
CcBBrNWzz0CMWUO5oOIIYevKEimtsDvBtlVaYJArJdwJq9KB/RjRAgMA//8=
-----END RSA PUBLIC KEY-----',
                       ),
    , 'add some content');

ok($transaction->submit(),'submit content');
ok($transaction->is_success(), 'it should succeed');
my $auth = $transaction->authorization();
ok($auth, 'should have an auth');

use MIME::Base64;
use Crypt::OpenSSL::RSA;
use Crypt::CBC;
use Storable;

my $privkey = '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDqCih9AmZurFhxoOEsoIpL7wHnA0vi8eopVGfJiFSXldnemIxC
UY8tdk0hXSUwtEogQ2yeFB8+Wsl4S0oStFb2kGPrH2cDF9UjWTWFMjvE+4GO0Asz
q3Ek0gnAQazVs89AjFlDuaDiCGHryhIprbA7wbZVWmCQKyXcCavSgf0Y0QIDAP//
AoGABlQEpEXw4vbz6yZwvRGkTunpSxRV5ZzIHZ4x3JjYQmGDoZRpf0SLz5p+eGFp
HtY+x1YaCfA9OIDU62GUhk3+l+QIuhjV0/2cnAQ8x81r82zmbioWcmkAyLYKrkgS
mKJHfWB2u7YRnTJLTPQ03GnTTNSJvxCRm9ns3xCJbe4dig8CQQD9ZMYMSRynzRXT
ri/yvEepml/Evs7M1aRsnGW19VddPi2HEFlbuHUiHxN661wH14fovMQfHyLHjRa4
GL9HovzLAkEA7HJsI1YTixoyjz4BXPLGksToA77EbZQIBA8f+p+4K/gRJXM1lkPb
LQlAMkVmpW3wWI23iqKdTqVRypZXUYYJUwJASNd7wc3aGZqOy8tTNdMTULVgEveI
e+w50y58b124/de4gBbUNrDp5Lvhnmw8fcGTpBu/YE2clgeFumtfj6BK2QJBAMPB
qpqX0LvdRzLwJ28MCUPxuos8TbmJ5IDIymF29p+Vej98dhzCgEn0T5MuGh4Vd623
2Wjm86Tc8Ojqimrvo80CQQC0hUQn1Qc3giMkxdBfBfmAgaOMUnGZ2LQ/xjc+6o3i
qkO/USX24l9TfRa0S+zPCnvgjnzEjBTsH6eF2S/wK2K5
-----END RSA PRIVATE KEY-----';

my ($key, $cipher) = split /:/, $auth;
$cipher = decode_base64($cipher);
$key = decode_base64($key);
ok($cipher, 'better have some data');
ok($key, 'better have some data here too');

my $rsa_priv;
eval {$rsa_priv = Crypt::OpenSSL::RSA->new_private_key($privkey)};
ok(!$@, 'looks like a valid private key');
my $seckey;
eval {$seckey = $rsa_priv->decrypt($key)};
ok(!$@, 'seckey decrypted');

my $ci = Crypt::CBC->new( {'key'             => $seckey,
                           'cipher'          => 'Blowfish',
                           });

my $plaintext = $ci->decrypt($cipher);

ok($plaintext, 'better be some plaintext');

my $data = Storable::thaw($plaintext);

#use Data::Dumper;
#my $foo = Data::Dumper->Dump([$data]);
#diag ($foo);

ok($cardnumber eq $data->{'cardnumber'}, 'get the cardnumber back');

use_ok(Business::OnlinePayment::StoredTransaction::Unstore);

my $store;
ok($store = Business::OnlinePayment::StoredTransaction::Unstore->new(
    private_key => $privkey,
    authorization => $auth,
), 'new store object');

ok($cardnumber eq $store->get('cardnumber'), 'cardnumber matches');
