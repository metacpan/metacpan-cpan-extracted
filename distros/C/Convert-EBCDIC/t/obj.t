# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..10\n";}
END {print "not ok 1\n" unless $loaded;}
use Convert::EBCDIC;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# This string "The quick brown fox: it jumped 123 brown cows!\n";
# in ASCII encoding
my $ascii_string  = 
"\124\150\145\040\161\165\151\143\153\040\142\162\157\167\156\040" .
"\146\157\170\072\040\151\164\040\152\165\155\160\145\144\040\061" .
"\062\063\040\142\162\157\167\156\040\143\157\167\163\041\012";

# and in CCSID 819 EBCDIC
my $ebcdic_string_819 = 
"\343\210\205\100\230\244\211\203\222\100\202\231\226\246\225\100" .
"\206\226\247\172\100\211\243\100\221\244\224\227\205\204\100\361" .
"\362\363\100\202\231\226\246\225\100\203\226\246\242\132\045";

# and in CCSID 1047 EBCDIC
my $ebcdic_string_1047 =
"\343\210\205\100\230\244\211\203\222\100\202\231\226\246\225\100" .
"\206\226\247\172\100\211\243\100\221\244\224\227\205\204\100\361" .
"\362\363\100\202\231\226\246\225\100\203\226\246\242\132\025";

my $tr = Convert::EBCDIC->new();
print "not " if ! $tr;
print "ok 2\n";

print "not " if ($tr->toebcdic($ascii_string) ne $ebcdic_string_819);
print "ok 3\n";

print "not " if ($tr->toascii($ebcdic_string_819) ne $ascii_string);
print "ok 4\n";

$tr = Convert::EBCDIC->new($Convert::EBCDIC::ccsid819);
print "not " if ! $tr;
print "ok 5\n";

print "not " if ($tr->toebcdic($ascii_string) ne $ebcdic_string_819);
print "ok 6\n";

print "not " if ($tr->toascii($ebcdic_string_819) ne $ascii_string);
print "ok 7\n";

$tr = Convert::EBCDIC->new($Convert::EBCDIC::ccsid1047);
print "not " if ! $tr;
print "ok 8\n";

print "not " if ($tr->toebcdic($ascii_string) ne $ebcdic_string_1047);
print "ok 9\n";

print "not " if ($tr->toascii($ebcdic_string_1047) ne $ascii_string);
print "ok 10\n";

