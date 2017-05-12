use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;

# NOTE: Just because we are testing that Crypt::Skip32 works with
# Crypt::CBC does not mean that it is a good idea.  In fact, we
# recommend against it.
#
# Crypt::Skip32 is intended for use in generating very small encrypted
# cipher text output which Crypt::CBC is not going to do.  If you want
# to encrypt more than a few bytes of text, consider using one of the
# proven secure Crypt::* ciphers with larger cipher block sizes.

BEGIN { $ENV{CRYPT_SKIP32_PP} = 1; }

SKIP: {
  eval "use Crypt::CBC 2.22";
  skip "Crypt::CBC not installed", 2, if $@;

  my $cbc_cipher = Crypt::CBC->new(
    -literal_key => 1,
    -key    	 => pack("H20", "DE2624BD4FFC4BF09DAB"),
    -iv     	 => pack("H8",  "7D8F7416"),
    -cipher 	 => 'Skip32',
    -header      => 'none',
  );

  my $number      = 3493209676;
  my $plaintext   = pack("N", $number);
  my $ciphertext  = $cbc_cipher->encrypt($plaintext);
  my $cipherhex   = unpack("H*", $ciphertext);
  is($cipherhex, '0de6cdf6c146bc02',
     "encrypt with Crypt::CBC");

  my $ciphertext2 = pack("H*", $cipherhex);
  my $plaintext2  = $cbc_cipher->decrypt($ciphertext);
  my $number2     = unpack("N", $plaintext2);
  is($number2, $number,
     "decrypt with Crypt::CBC");
}
