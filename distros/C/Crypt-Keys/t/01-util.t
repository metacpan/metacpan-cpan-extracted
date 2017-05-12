# $Id: 01-util.t,v 1.1 2001/07/11 07:22:31 btrott Exp $

use strict;

use Test;
use Math::Pari;
use Crypt::Keys::Util qw( bin2mp mp2bin bitsize );

BEGIN { plan tests => 10 }

my($string, $num, $n);

$string = "abcdefghijklmnopqrstuvwxyz-0123456789";
$num = PARI("48431489725691895261376655659836964813311343892465012587212197286379595482592365885470777");
$n = bin2mp($string);
ok($n, $num);
ok(bitsize($num), 295);
ok(bitsize($n), 295);
ok(mp2bin($n), $string);

$string = "abcd";
$num = 1_633_837_924;
$n = bin2mp($string);
ok($n, $num);
ok(bitsize($num), 31);
ok(bitsize($n), 31);
ok(mp2bin($n), $string);

$string = "";
$num = 0;
$n = bin2mp($string);
ok($n, $num);
ok(mp2bin($n), $string);
