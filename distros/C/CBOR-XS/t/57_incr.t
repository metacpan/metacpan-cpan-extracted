BEGIN { $| = 1; print "1..123\n"; }

use CBOR::XS;

print "ok 1\n";
my $tst = 1;

sub tst($$) {
   my ($cbor, $correct) = @_;

   my $dec = CBOR::XS->new;

   # chop
   for my $step (1 .. length $cbor) {
      my $buf = "";
      my @cbor;

      $dec->incr_reset;

      for (unpack "(a$step)*", $cbor) {
         $buf .= $_;
         push @cbor, $dec->incr_parse_multiple ($buf);
      }

      print length $buf ? "not " : "", "ok ", ++$tst, "\n";

      my $enc = join " ", map +(unpack "H*", encode_cbor $_), @cbor;

      print $enc eq $correct ? "" : "not ", "ok ", ++$tst, " # ($step) $enc eq $correct\n";
   }
}

sub err($$) {
   if (eval { CBOR::XS->new->max_size (1e3)->incr_parse ($_[0]); 1 }) {
      print "not ok ", ++$tst, " # unexpected success\n";
   } elsif ($@ =~ $_[1]) {
      print "ok ", ++$tst, "\n";
   } else {
      print "not ok ", ++$tst, " # $@\n";
   }
}

tst "\x81\x82\x81\x80\x80\x80", "8182818080 80";
tst "\x01\x18\x55\x01", "01 1855 01";
#tst "\x18\x01\x19\x02\x02\x1a\x04\x04\x04\x04\x1b\x08\x08\x08\x08\x08\x08\x08\x08\x00", "01 190202 1a04040404 1b0808080808080808 00";
tst "\x18\x01\x19\x02\x02\x1a\x04\x04\x04\x04\x00", "01 190202 1a04040404 00";
tst "\x41A\x42CD", "4141 424344";
tst "\x58\x01A\x59\x00\x01B\x5a\x00\x00\x00\x01C\x5b\x00\x00\x00\x00\x00\x00\x00\x02XY\x01", "4141 4142 4143 425859 01";
tst "\x5f\x41A\x41B\x42CD\xff", "4441424344";
err "\xff", "major 7";
err "\x5a\xff\x00\x00\x00", "max_size";

