use strict;

use Test::More;
use Test::Exception;

use DTOne::Crypt qw(encrypt_aes256gcm decrypt_aes256gcm);

my $key       = "YL61pQsgFez6rQnNjRkI0glz6PoXnctdzWcoA3bEfNs=";
my $plaintext = "Lorem Ipsum";

subtest 'Basic roundtrip' => sub {
    my $encrypted = encrypt_aes256gcm($plaintext, $key);
    my $decrypted = decrypt_aes256gcm($encrypted, $key);
    is($decrypted, $plaintext, "decrypting message matches original");
};

subtest 'Data validation' => sub {
    throws_ok { encrypt_aes256gcm(undef, $key) } qr/plaintext data required/;
    lives_ok  { encrypt_aes256gcm('',    $key) } 'empty string as plaintext is allowed';
    lives_ok  { encrypt_aes256gcm(0,     $key) } '0 as plaintext is allowed';

    throws_ok { encrypt_aes256gcm($plaintext, undef) } qr/key required/;
    throws_ok { encrypt_aes256gcm($plaintext, '') } qr/key required/;
    throws_ok { encrypt_aes256gcm($plaintext, substr($key, 0, 10)) } qr/invalid master key length/;
    dies_ok   { encrypt_aes256gcm($plaintext, 'not:b64') } qr/invalid base64 as encryption key dies/;

    throws_ok { decrypt_aes256gcm(undef, $key) } qr/encrypted data required/;
    throws_ok { decrypt_aes256gcm('',    $key) } qr/encrypted data required/;
    throws_ok { decrypt_aes256gcm(0,     $key) } qr/encrypted data required/;
    lives_ok  { decrypt_aes256gcm('not:b64', $key) } qr/invalid base64 chars in encrypted data are simply ignored/;

    throws_ok { decrypt_aes256gcm($plaintext, undef) } qr/key required/;
    throws_ok { decrypt_aes256gcm($plaintext, '') } qr/key required/;
    throws_ok { decrypt_aes256gcm($plaintext, substr($key, 0, 10)) } qr/invalid master key length/;
    dies_ok   { decrypt_aes256gcm($plaintext, 'not:b64') } qr/invalid base64 as decryption key dies/;
};

subtest 'v1 data compatibility' => sub {
    my $v1_encrypted = "rGAfqqJBDGuEcU86liIQgEUvDYcS+nS0Q9w/AnagVKgWFuA6aLlDNAucQFR87FHBIKKZ/91x0Q==";
    my $decrypted = decrypt_aes256gcm($v1_encrypted, $key);
    is($decrypted, $plaintext, "decrypting v1 encrypted message matches original");
};

done_testing;
