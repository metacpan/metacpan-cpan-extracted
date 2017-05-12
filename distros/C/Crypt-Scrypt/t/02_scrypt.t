use strict;
use warnings;
use Test::More;
use Crypt::Scrypt;

for my $pair (['', ''], [qw(plaintext key)]) {
    my ($in, $key) = @$pair;

    local $@;
    my $ciphertext = eval { Crypt::Scrypt->encrypt($in, key => $key) };
    if ($@) {
        plan skip_all => qq(scrypt doesn't appear to work on this system: $@);
    }

    is(length($ciphertext), 128 + length($in), 'length of ciphertext');
    my $plaintext = Crypt::Scrypt->decrypt(
        $ciphertext, key => $key, max_time => 30, max_mem_frac => 0.5
    );
    is($plaintext, $in, 'decrypted ciphertext same as plaintext');
}

{
    local $@;
    eval {
        my $ciphertext = Crypt::Scrypt->encrypt(
            'plaintext', key => 'key', max_time => 10
        );
        my $plaintext = Crypt::Scrypt->decrypt(
            $ciphertext, key => 'key', max_time => 1
        );
    };
    like($@, qr/^decrypting input would take too long/, 'insufficient time');
}

done_testing;
