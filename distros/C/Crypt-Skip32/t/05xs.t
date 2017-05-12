use strict;
use warnings;
use Test::More;

eval 'use Crypt::Skip32::XS';
if ( $@ ) {
  plan skip_all => 'Crypt::Skip32::XS is not installed';
} else {
  plan tests => 5;

  my $cipher = new Crypt::Skip32::XS pack("H20", "00998877665544332211");
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
}
