use Test::More tests => 45;
use strict;
use warnings;
use FindBin;
use Crypt::Keyczar qw(KEY_HASH_SIZE FORMAT_VERSION);

sub BEGIN { use_ok('Crypt::Keyczar::Signer') }

my $signer = Crypt::Keyczar::Signer->new("$FindBin::Bin/data/signer");
ok($signer, 'create signer with HMAC-SHA1');
my $sign = $signer->sign("Hello World!");
ok($sign, 'create sign');

my $l = KEY_HASH_SIZE();
my ($version, $hash, $mac) = unpack "C1 a$l a*", $sign;
ok($version == FORMAT_VERSION(), 'version check');
ok($hash eq "\xf2\x4b\xe1\x6f", 'key hash');
ok($mac eq "\xf0\x4a\x59\x82\xc3\x8d\xfe\x35\x6e\x4f\x85\x28\x00\xa9\x36\x79\x5d\x33\x31\xca", 'mac');

ok($sign = $signer->sign("Hello World!", time() + 5*60), 'with expiration sign');
ok($signer->verify("Hello World!", $sign), 'with expiration veriry');
$sign = $signer->sign("Hello World!", time() - 5*60);
ok(!$signer->verify("Hello World!", $sign), 'with expired veriry');


SKIP: {
    skip "SHA224 not supported", 9 if !Crypt::Keyczar::HmacEngine->is_supported('SHA224');

    $signer = Crypt::Keyczar::Signer->new("$FindBin::Bin/data/signer-hmac-sha224");
    ok($signer, 'create signer with HMAC-SHA224');
    $sign = $signer->sign("Hello World!");
    ok($sign, 'create sign');
    $l = KEY_HASH_SIZE();
    ($version, $hash, $mac) = unpack "C1 a$l a*", $sign;
    ok($version == FORMAT_VERSION(), 'version check');
    ok($hash eq "\xf2\x4b\xe1\x6f", 'key hash');
    ok($mac eq "\xe9\xe6\x6f\xc5\x6e\x1b\xfb\x51\x9b\xe8\x12\x22\x96\x8c\xe4\x10\x87\x63\x46\x56\xb4\xcd\x62\x9f\xf5\x3d\xe3\x30", 'mac');
    ok($signer->verify('Hello World!', $sign));

    ok($sign = $signer->sign("Hello World!", time() + 5*60), 'with expiration sign');
    ok($signer->verify("Hello World!", $sign), 'with expiration veriry');
    $sign = $signer->sign("Hello World!", time() - 5*60);
    ok(!$signer->verify("Hello World!", $sign), 'with expired veriry');
}

SKIP: {
    skip "SHA256 not supported", 9 if !Crypt::Keyczar::HmacEngine->is_supported('SHA256');

    $signer = Crypt::Keyczar::Signer->new("$FindBin::Bin/data/signer-hmac-sha256");
    ok($signer, 'create signer with HMAC-SHA256');
    $sign = $signer->sign("Hello World!");
    ok($sign, 'create sign');
    $l = KEY_HASH_SIZE();
    ($version, $hash, $mac) = unpack "C1 a$l a*", $sign;
    ok($version == FORMAT_VERSION(), 'version check');
    ok($hash eq "\xf2\x4b\xe1\x6f", 'key hash');
    ok($mac eq "\xa7\xe4\x63\x29\xe9\xf4\xd4\xec\xca\x57\x95\xf0\x90\x76\x86\x4c\x92\x75\x4d\x11\xc6\xf7\x5b\x1a\x23\xde\x26\x2b\x61\x35\x43\x25", 'mac');
    ok($signer->verify('Hello World!', $sign));

    ok($sign = $signer->sign("Hello World!", time() + 5*60), 'with expiration sign');
    ok($signer->verify("Hello World!", $sign), 'with expiration veriry');
    $sign = $signer->sign("Hello World!", time() - 5*60);
    ok(!$signer->verify("Hello World!", $sign), 'with expired veriry');
}

SKIP: {
    skip "SHA384 not supported", 9 if !Crypt::Keyczar::HmacEngine->is_supported('SHA384');

    $signer = Crypt::Keyczar::Signer->new("$FindBin::Bin/data/signer-hmac-sha384");
    ok($signer, 'create signer with HMAC-SHA384');
    $sign = $signer->sign("Hello World!");
    ok($sign, 'create sign');
    $l = KEY_HASH_SIZE();
    ($version, $hash, $mac) = unpack "C1 a$l a*", $sign;
    ok($version == FORMAT_VERSION(), 'version check');
    ok($hash eq "\xf2\x4b\xe1\x6f", 'key hash');
    ok($mac eq "\x30\x90\x4d\xab\xa5\x69\x36\x46\x6f\x80\x76\x03\xd9\x25\x8f\xfd\x2d\x7c\x1c\x85\x24\xdc\x61\x03\xed\x81\x17\x2e\x8a\x59\x67\xd2\x33\x0f\x5e\x03\x8b\xdc\xf4\x18\xc6\x4b\xec\xe9\x2a\xd9\xc1\xd4", 'mac');
    ok($signer->verify('Hello World!', $sign));

    ok($sign = $signer->sign("Hello World!", time() + 5*60), 'with expiration sign');
    ok($signer->verify("Hello World!", $sign), 'with expiration veriry');
    $sign = $signer->sign("Hello World!", time() - 5*60);
    ok(!$signer->verify("Hello World!", $sign), 'with expired veriry');
}

SKIP: {
    skip "SHA512 not suppoorted", 9 if !Crypt::Keyczar::HmacEngine->is_supported('SHA512');
    $signer = Crypt::Keyczar::Signer->new("$FindBin::Bin/data/signer-hmac-sha512");
    ok($signer, 'create signer with HMAC-SHA512');
    $sign = $signer->sign("Hello World!");
    ok($sign, 'create sign');
    $l = KEY_HASH_SIZE();
    ($version, $hash, $mac) = unpack "C1 a$l a*", $sign;
    ok($version == FORMAT_VERSION(), 'version check');
    ok($hash eq "\xf2\x4b\xe1\x6f", 'key hash');
    ok($mac eq "\xe3\x6b\x9e\xc7\x69\x12\xad\x9e\x23\x90\x7d\xc3\xb6\x30\xc0\x1f\x6e\x77\x1f\x41\x00\x62\xc7\xe5\x44\x97\xf9\x07\xbe\x0f\x8a\x4e\x8a\xcf\x49\x4f\x0d\x39\x46\x75\xc8\x68\x8a\xb4\x7b\x3e\xa4\x6a\x93\x5e\x84\xaa\xa7\x1b\xdf\x95\xd5\xc5\x5c\x10\xa9\xa9\x18\x5d", 'mac');
    ok($signer->verify('Hello World!', $sign));

    ok($sign = $signer->sign("Hello World!", time() + 5*60), 'with expiration sign');
    ok($signer->verify("Hello World!", $sign), 'with expiration veriry');
    $sign = $signer->sign("Hello World!", time() - 5*60);
    ok(!$signer->verify("Hello World!", $sign), 'with expired veriry');
}
