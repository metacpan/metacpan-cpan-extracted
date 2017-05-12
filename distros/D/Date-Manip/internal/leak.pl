#!/usr/bin/perl

$a1  = '(?<a>\d)';

$a2  = $a1;
#$a2 = '(?<b>\d)';

$b   = '\d';

$rx  = qr/(?:${a}${b}|${a2}:${b})/;

#$string = "12";
$string = "1:2";

while (1) {
   $string =~ $rx;
   $tmp = $+{a};
}
