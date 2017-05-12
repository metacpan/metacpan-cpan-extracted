use strict;
use Test::More tests => 6;

use Convert::PEM::CBC;

my $KEY = pack "H64", ("0123456789ABCDEF" x 4);
my $IV  = "\0" x 8;

my($cbc1, $cbc2);

$cbc1 = Convert::PEM::CBC->new(
                  Cipher => 'Crypt::DES_EDE3',
                  Key    => $KEY,
                  IV     => $IV,
         );
isa_ok $cbc1, 'Convert::PEM::CBC';

$cbc2 = Convert::PEM::CBC->new(
                  Cipher => 'Crypt::DES_EDE3',
                  Key    => $KEY,
                  IV     => $IV,
         );
isa_ok $cbc2, 'Convert::PEM::CBC';

my($enc, $dec);
$enc = $cbc1->encrypt( _checkbytes() );
ok defined $enc, 'got something from encrypt';
$dec = $cbc2->decrypt($enc);
ok defined $dec, 'got something from decrypt';

is vec($dec, 0, 8), vec($dec, 2, 8), 'input1 matches output1';
is vec($dec, 1, 8), vec($dec, 3, 8), 'input2 matches output2';

sub _checkbytes {
    my($check1, $check2) = (chr int rand 255, chr int rand 255);
    "$check1$check2$check1$check2";
}
