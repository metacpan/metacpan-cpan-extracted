use strict;
use warnings;
use Test::More tests => 3;

use Crypt::OpenSSL::AES;
use Crypt::URandom qw( urandom );

# Basic usage (defaults to AES-ECB based on key length; ECB is not recommended)
my $key    = urandom(32);
my $cipher = Crypt::OpenSSL::AES->new($key);

# Recommended usage: AES-256-CBC with proper Initialization Vector and Padding
my $secure_key = urandom(32); # 32 bytes (256 bits) for AES-256
my $iv         = urandom(16); # 16 bytes (128 bits) block size for AES

my $secure_cipher = Crypt::OpenSSL::AES->new(
    $secure_key,
    {
        cipher  => 'AES-256-CBC',
        iv      => $iv,
        padding => 1, # 1 for standard block padding, 0 for no padding
    }
);
isa_ok($secure_cipher, 'Crypt::OpenSSL::AES');

my $plaintext = "Confidential data to be encrypted.";
my $encrypted = $secure_cipher->encrypt($plaintext);
unlike($encrypted, qr/Confidential data to be encrypted./, "Data encrypted");

my $decrypted = $secure_cipher->decrypt($encrypted);
like($decrypted, qr/Confidential data to be encrypted./, "Plaintext matches Decrypted value");
