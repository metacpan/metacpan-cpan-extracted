# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use utf8;
use Test;
use strict;
use vars qw/$loaded/;

BEGIN 
  {
  $| = 1;
  unshift @INC,'../lib';
  chdir 't' if -d 't';
  plan tests => 8;
  }
END 
  {
  print "not ok 1\n" unless $loaded;
  }

use Convert::Braille;
$loaded = 1;
ok (1,1);

######################### End of black magic.

if ( $] > 5.007 ) {
	binmode(STDOUT, ":utf8");
}



my ($try,$rc);

$try = "brailleAscii_To_Unicode('HELLO');";
$rc = eval $try;
print " # '$try' expected '⠓⠑⠇⠇⠕' but got '$rc'\n" 
	unless ok ($rc,"⠓⠑⠇⠇⠕");

$try = "brailleAscii_To_Unicode('hello');";
$rc = eval $try;
print " # '$try' expected '⠓⠑⠇⠇⠕' but got '$rc'\n" 
	unless ok ($rc,"⠓⠑⠇⠇⠕");

$try = "brailleAscii_To_DotNumbers('HELLO');";
$rc = eval $try;
print " # '$try' expected '12515123123135' but got '$rc'\n" 
	unless ok ($rc,"12515123123135");

$try = "brailleDotNumbers_To_Ascii('12515123123135');";
$rc = eval $try;
print " # '$try' expected 'HELLO' but got '$rc'\n" 
	unless ok ($rc,'HELLO');

$try = "brailleDotNumbers_To_Unicode('12515123123135');";
$rc = eval $try;
print " # '$try' expected '⠓⠑⠇⠇⠕' but got '$rc'\n" 
	unless ok ($rc,'⠓⠑⠇⠇⠕');

$try = "brailleUnicode_To_DotNumbers('⠓⠑⠇⠇⠕');";
$rc = eval $try;
print " # '$try' expected '12515123123135' but got '$rc'\n" 
	unless ok ($rc,"12515123123135");

$try = "brailleUnicode_To_Ascii('⠓⠑⠇⠇⠕');";
$rc = eval $try;
print " # '$try' expected 'HELLO' but got '$rc'\n" 
	unless ok ($rc,'HELLO');

1;
__END__
