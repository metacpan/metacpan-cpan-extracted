#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3;

my @ciphers = Crypt::OpenSSL3::Cipher->list_all_provided;
ok @ciphers, 'Got ciphers';

my $has_aes = grep { $_->get_name eq 'AES-128-GCM' } @ciphers;
ok $has_aes, 'Has aes';

my $key = "0123456789ABCDEF";
my $iv = substr $key, 0, 12;

my $cipher = Crypt::OpenSSL3::Cipher->fetch('AES-128-GCM');
ok $cipher, 'Fetched AES-128-GCM';

my $context = Crypt::OpenSSL3::Cipher::Context->new;
$context->init($cipher, $key, $iv, 1, { padding => 0 }) or die;

is $context->get_param('ivlen'), 12;
my $plain = "Hello, World!";

my $enc1 = $context->update($plain) // die;
my $enc2 = $context->final // die;
my $ciphertext = $enc1 . $enc2;
is length $ciphertext, length $plain, 'Ciphertext has the right length';
my $tag = $context->get_aead_tag;
ok length $tag;

my $context2 = Crypt::OpenSSL3::Cipher::Context->new;
$context2->init($cipher, $key, $iv, 0) or die;

my $dec1 = $context2->update($ciphertext) // die;
ok $context2->set_aead_tag($tag);
my $dec2 = $context2->final // die;

my $decoded = $dec1 . $dec2;

is $decoded, $plain, 'Decoded text matches original plaintext';

done_testing;
