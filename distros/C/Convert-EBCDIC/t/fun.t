# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use Convert::EBCDIC qw(ascii2ebcdic ebcdic2ascii);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#use Convert::EBCDIC qw(ascii2ebcdic ebcdic2ascii);
# "The quick brown fox: it jumped 123 brown cows!\n";
my $ascii_string  = 
"\124\150\145\040\161\165\151\143\153\040\142\162\157\167\156\040" .
"\146\157\170\072\040\151\164\040\152\165\155\160\145\144\040\061" .
"\062\063\040\142\162\157\167\156\040\143\157\167\163\041\012";

my $ebcdic_string = 
"\343\210\205\100\230\244\211\203\222\100\202\231\226\246\225\100" .
"\206\226\247\172\100\211\243\100\221\244\224\227\205\204\100\361" .
"\362\363\100\202\231\226\246\225\100\203\226\246\242\132\045";


print "not " if (ebcdic2ascii(ascii2ebcdic($ascii_string)) ne $ascii_string);
print "ok 2\n";

print "not " if (ascii2ebcdic(ebcdic2ascii($ebcdic_string)) ne $ebcdic_string);
print "ok 3\n";

