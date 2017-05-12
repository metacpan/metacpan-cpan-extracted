use strict;
use warnings;
require 5.008;

use Test::More tests => 3;

my $s = "_sixteen__chars_";
my $correct = '2f 2d d4 2d 9f 88 52 d5 b cf 56 41 c4 c4 8c b3';

BEGIN { use_ok( 'Crypt::AppleTwoFish' ); }

my $object = Crypt::AppleTwoFish->new( key => $s );
isa_ok ($object, 'Crypt::AppleTwoFish');
my $sd = $object->decrypted_for_iTMS;
my $shx = sprintf("%x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x", 
  map { ord }  split //, $sd);

print "\n$shx\n$correct\n";

ok($shx eq $correct, "16 byte decryption test");

