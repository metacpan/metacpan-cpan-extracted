use strict;
use warnings;
use Test::More;

BEGIN {
  eval 'use Crypt::Skip32 0.19';
  if ( $@ ) {
    plan tests => 1;
    use_ok('Crypt::Skip32', 0.19);
    exit(1);
  } else {
    eval 'use Crypt::Skip32::XS';
    if ( $@ ) {
      plan skip_all => 'Crypt::Skip32::XS is not installed';
    } 
  }
}

plan tests => 6;

my $key = pack("H20", "00998877665544332211");

#Indirect object invocation of Crypt::Skip32 should return a Crypt::Skip32::XS object
my $cipher = new Crypt::Skip32 $key;
isa_ok($cipher, 'Crypt::Skip32::XS');

#Crypt::Skip32->new should return a Crypt::Skip32::XS object
$cipher = Crypt::Skip32->new($key);
isa_ok($cipher, 'Crypt::Skip32::XS');

is($cipher->blocksize, 4, "blocksize is 4");
is($cipher->keysize, 10, "keysize is 10");

my $plain_number  = 0x33221100;
my $plain_text_1  = pack('N', $plain_number);
my $cipher_text   = $cipher->encrypt($plain_text_1);
my $plain_text_2  = $cipher->decrypt($cipher_text);
my $cipher_number = unpack('N', $cipher_text);

is($cipher_number, 0x819D5F1F,
  "Skip32 encrypt $plain_number -> $cipher_number");

is($plain_text_1, $plain_text_2,
  "Skip32 decrypt $cipher_number -> $plain_number");

