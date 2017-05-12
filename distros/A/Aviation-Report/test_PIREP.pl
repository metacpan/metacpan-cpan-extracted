# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Aviation::Report;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

   my $DEBUG = 1;

   my @in = (
   "UA/OV OKC 063064/TM 1522/FL 080/TP CE172/SK 020 BKN 045/060 OVC 070/TA -04/WV 245040/TB LGT/RM IN CLR",
   "UA/OV OKC/TM 1522/FL 080/TP CE172/SK 020 BKN 045/060 OVC 070/TA -04/WV 245040/TB LGT/RM IN CLR/IC MDT",

);

   my $i=2;

   foreach (@in) {
      my $out='';
      if ($out = decode_PIREP($_, 0)) {
         print "ok";
      }
      else {
         print "not ok";
      }
      print ' ', $i++, "\n";
      print $out if $DEBUG;
   }
__END__
