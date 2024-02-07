#!/usr/bin/env perl

use 5.006;
use strict; use warnings;
use Crypt::Image;
use Test::More tests => 3;

my $crypter = Crypt::Image->new(file => 't/key.png', type => 'png');

eval { $crypter->encrypt() };
like($@, qr/ERROR: Encryption text is missing./);

eval { $crypter->encrypt('Hello World') };
like($@, qr/ERROR: Decrypted file name is missing./);

# Test key image t/key.png is 313x227, therefore the maximum length
# of the encryption text would be (313*227)-2 i.e. 71049.
my $encrypt = 'A' x 71050;
eval { $crypter->encrypt($encrypt, 't/secret.png') };
like($@, qr/ERROR: Encryption text is too long./);
