# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Formatter-Text.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Crypt::Rot47') };

# Test that the appropriate methods exist
can_ok('Crypt::Rot47', 'new', 'encrypt', 'decrypt', 'rot47');

my $plaintext = 'Hello world';
my $cipher = Crypt::Rot47->new();

# Test that text is changed by encryption
my $ciphertext = $cipher->encrypt($plaintext);
isnt($ciphertext, $plaintext, 'encrypt scrambles text');

# Test that the text is unscrambed by decryption
my $decrypted_text = $cipher->decrypt($ciphertext);
is($decrypted_text, $plaintext, 'decrypt unscrambles scrambled text');

# Test that the ciphertext generated matches what we know to be correct
my $fox = 'The Quick Brown Fox Jumps Over The Lazy Dog.';
my $encrypted_fox = $cipher->encrypt($fox);
is ($encrypted_fox, '%96 "F:4< qC@H? u@I yF>AD ~G6C %96 {2KJ s@8]',
    'encryption of test message generates expected ciphertext');


