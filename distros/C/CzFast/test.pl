
# $Id: test.pl,v 1.3 2001/03/19 19:59:39 trip Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..last_test_to_print\n"; }
END { print "not ok 1\n" unless $loaded; }

use CzFast qw ( &czregexp &czrecode );

$str = 'Seriál krok za krokem vysvìtluje vše potøebné pro tvorbu webovských stránek -- zejména popis jazyka HTML a dalších potøebných dovedností jako tvorba klikacích map, transparentních a animovaných obrázkù atd.';

print "Following text is in windows-1250 encoding, you'll se it corrupted:\n";
print "$str\n\n";

##############################################################################

print "2..iso-8859-2 conversion\n";
print "And now in iso-8859-2 encoding:\n";
print &czrecode ('windows-1250', 'iso-8859-2', $str)."\n";
print "ok 2\n\n";

##############################################################################

print "3..ascii conversion\n";
print "And now in pure ascii:\n";
print &czrecode ('windows-1250', 'us-ascii', $str)."\n";
print "ok 3\n\n";

##############################################################################

print "4..cz diacritic insensitive regexp of 'Pokusny test'\n";
print &czregexp ('Pokusny test.')."\n";
print "ok 4\n\n";

$loaded = 1;
print "ok 1\n";
