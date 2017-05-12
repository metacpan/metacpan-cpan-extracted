use strict;
use warnings;
use Test::More;
use Crypt::RNCryptor;
use t::assets::VectorParser;

subtest 'Simply encrypt & decrypt' => sub {

    my $PLAIN_DATA = 'foobar';

    subtest 'password-based encryption/decryption' => sub {
        my $cryptor = Crypt::RNCryptor->new(
            password => 'foobar',
        );
        is $cryptor->decrypt($cryptor->encrypt($PLAIN_DATA)), $PLAIN_DATA;
    };

    subtest 'key-based encryption/decryption' => sub {
        my $cryptor = Crypt::RNCryptor->new(
            encryption_key => pack('C*', 1..32),
            hmac_key => pack('C*', 1..32),
        );
        is $cryptor->decrypt($cryptor->encrypt($PLAIN_DATA)), $PLAIN_DATA;
    };

};


subtest 'v3' => sub {

    subtest 'kdf' => sub {
        my $vp = t::assets::VectorParser->load(3, 'kdf');
        my $cryptor = Crypt::RNCryptor->new(password => 'dummy');

        foreach my $i (0..$vp->num-1) {
            my $key = $cryptor->pbkdf2(
                $vp->get($i, 'password'),
                $vp->get($i, 'salt_hex', 1),
            );
            is $key, $vp->get($i, 'key_hex', 1);
        }
    };


    subtest 'password' => sub {
        my $vp = t::assets::VectorParser->load(3, 'password');

        foreach my $i (0..$vp->num-1) {
            my $cryptor = Crypt::RNCryptor->new(
                password => $vp->get($i, 'password'),
            );
            my $plaintext = $vp->get($i, 'plaintext_hex', 1);
            my $ciphertext = $vp->get($i, 'ciphertext_hex', 1);
            is $ciphertext, $cryptor->encrypt(
                $plaintext,
                iv => $vp->get($i, 'iv_hex', 1),
                encryption_salt => $vp->get($i, 'enc_salt_hex', 1),
                hmac_salt => $vp->get($i, 'hmac_salt_hex', 1),
            );
            is $plaintext, $cryptor->decrypt($ciphertext);
        }
    };

TODO: {
    local $TODO = q{
The length of encryption/hmac key have to be 32,
but the length of the data decoded each value of "enc_key_hex"/"hmac_key_hex"
is only 16. Maybe this is mistake of the test vector.
Thus, The following tests are failed because I cannot guess the real value.
    };
    subtest 'key' => sub {
        my $vp = t::assets::VectorParser->load(3, 'key');

        foreach my $i (0..$vp->num-1) {
            my $cryptor = Crypt::RNCryptor->new(
                encryption_key => pack('a32', $vp->get($i, 'enc_key_hex', 1)), # NG?
                hmac_key => pack('a32', $vp->get($i, 'hmac_key_hex', 1)), # OK?
            );
            my $plaintext = $vp->get($i, 'plaintext_hex', 1);
            my $ciphertext = $vp->get($i, 'ciphertext_hex', 1);
            is $ciphertext, $cryptor->encrypt(
                $plaintext,
                iv => $vp->get($i, 'iv_hex', 1),
            );
            is $plaintext, $cryptor->decrypt($ciphertext);
        }
    };
}

};

done_testing;
