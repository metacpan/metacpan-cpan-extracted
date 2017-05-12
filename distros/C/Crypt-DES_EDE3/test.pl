# $Id: test.pl,v 1.2 2001/09/15 03:38:24 btrott Exp $

use strict;

use Test;
use Crypt::DES_EDE3;
use strict;

BEGIN { plan tests => 7 }

my $des = Crypt::DES_EDE3->new( pack 'H64', '0123456789ABCDEF' x 4 );
ok($des);
ok($des->keysize, 24);

my $enc = $des->encrypt( _checkbytes() );
ok($enc);
my $dec = $des->decrypt($enc);
ok($dec);

ok( vec($dec, 0, 8) == vec($dec, 2, 8) );
ok( vec($dec, 1, 8) == vec($dec, 3, 8) );
ok( vec($dec, 5, 8) == 0 );

sub _checkbytes {
    my($check1, $check2) = (chr int rand 255, chr int rand 255);
    "$check1$check2$check1$check2\0\0\0\0";
}
