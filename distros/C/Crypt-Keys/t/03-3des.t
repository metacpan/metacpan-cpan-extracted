# $Id: 03-3des.t,v 1.2 2002/02/16 18:29:57 btrott Exp $

use strict;

use Test;

BEGIN {
    eval "use Crypt::CBC; use Crypt::DES;";
    if ($@) {
        print "1..0 skipping\n";
        exit;
    }

    plan tests => 6;
}

use Crypt::Keys::Private::RSA::SSH1;

my $KEY = pack "H64", ("0123456789ABCDEF" x 4);
my $IV  = "\0" x 8;

my($des1, $des2);

$des1 = Crypt::Keys::Private::RSA::SSH1::DES3->new($KEY);
ok($des1);

$des2 = Crypt::Keys::Private::RSA::SSH1::DES3->new($KEY);
ok($des2);

my($enc, $dec);
$enc = $des1->encrypt( _checkbytes() );
ok($enc);
$dec = $des2->decrypt($enc);
ok($dec);

ok( vec($dec, 0, 8) == vec($dec, 2, 8) );
ok( vec($dec, 1, 8) == vec($dec, 3, 8) );

sub _checkbytes {
    my($check1, $check2) = (chr int rand 255, chr int rand 255);
    "$check1$check2$check1$check2";
}
