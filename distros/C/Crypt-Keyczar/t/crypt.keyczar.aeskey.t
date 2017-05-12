use Test::More tests => 14;
use strict;
use warnings;
use Crypt::Keyczar::Util;

BEGIN { use_ok 'Crypt::Keyczar::Key' }

my $key;
$key = Crypt::Keyczar::Key->read_key('AES', q|{"hmacKey": {"hmacKeyString": "9_4wqXs3fyx4VhUCGVN6DelPuuC1XYy-oY2oVxOJ8t0", "size": 256}, "aesKeyString": "lSWq_bw7UIpssD4AvwIEjw", "mode": "CBC", "size": 128}|);
ok($key);
ok($key->get_bytes eq pack 'H*', '9525aafdbc3b508a6cb03e00bf02048f');
ok($key->{size} == 128);
ok($key->{mode} eq 'CBC');
ok($key->{hmacKey}->get_bytes eq pack 'H*', 'f7fe30a97b377f2c7856150219537a0de94fbae0b55d8cbea18da8571389f2dd');
ok($key->{hmacKey}->{hmacKeyString} eq '9_4wqXs3fyx4VhUCGVN6DelPuuC1XYy-oY2oVxOJ8t0');
ok($key->{hmacKey}->{size} == 256);

my $obj = Crypt::Keyczar::Util::decode_json($key->to_string);
ok($obj);
ok($obj->{aesKeyString} eq 'lSWq_bw7UIpssD4AvwIEjw');
ok($obj->{mode} eq 'CBC');
ok($obj->{size} == 128);
ok($obj->{hmacKey}->{hmacKeyString} eq '9_4wqXs3fyx4VhUCGVN6DelPuuC1XYy-oY2oVxOJ8t0');
ok($obj->{hmacKey}->{size} == 256);
