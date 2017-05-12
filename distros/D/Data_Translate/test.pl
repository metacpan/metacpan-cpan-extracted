#!/usr/bin/perl
$str="some string";
print "Using \"$str\" as test!\n";

use Data::Translate;
$loaded=1;

print "test 1: ";
if ($loaded) { print "ok!\n" } else { print "err!\n"; exit 1; }

print "test 2: ";
$data=new Translate;
($status,$binstring)=$data->a2b($str);
if ($status) { print "ok!\n"; } else { print "err!\n"; exit 1; }

print "test 3: ";
($st_b2a,$txt_b2a)=$data->b2a($binstring);
if ($str eq $txt_b2a) { print "ok!\n"; } else { print "err!\n"; exit 1; }

print "test 4: ";
($st_a2d,$txt_a2d)=$data->a2d($str);
if ($st_a2d) { print "ok!\n"; } else { print "err!\n"; exit 1; }

print "OK! All tests are gooooooood!\n";
