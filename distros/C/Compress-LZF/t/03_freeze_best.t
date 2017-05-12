BEGIN {
   eval "use Storable; 1" or do {
      print "1..0 # skip Storable module unavailable\n";
      exit;
   };
}

BEGIN { $| = 1; print "1..1959\n"; }

END {print "not ok 1\n" unless $loaded;}
use Compress::LZF ':freeze';
use Storable;
$loaded = 1;
print "ok 1\n";

$tst = 0;

sub ok {
   print (($_[0] ? "ok " : "not ok "), 1+ ++$tst, "\n");
}

sub chk {
   my $s = shift;
   my $n  = sfreeze_best    $s; ok(1);
   my $nr = sfreeze_cr_best $s; ok(1);
   my $nc = sfreeze_c_best  $s; ok(1);
   my $r  = sfreeze_best   \$s; ok(1);
   my $rr = sfreeze_cr_best\$s; ok(1);
   my $rc = sfreeze_c_best \$s; ok(1);

   ok (length ($n) >= length ($nc));
   ok (length ($n) <= length ($r));
   ok (length ($r) >= length ($rr));
   ok ($rr eq $rc);
   ok (length ($r) >= length ($rr));

   #print unpack("H*", $s), " => ", unpack("H*", $rc), "\n";

   ok ($s eq sthaw $n);
   ok ($s eq sthaw $nr);
   ok ($s eq sthaw $nc);
   ok ($s eq ${sthaw $r});
   ok ($s eq ${sthaw $rr});
   ok ($s eq ${sthaw $rc});
}

for my $pfx (0, 1, 4, 6, 7, 40, ord('x'), 240..255) {
   chk $pfx;
   $pfx =~ /(.*)/;
   chk $1;
   chk chr($pfx)."x";
   chk chr($pfx)."xxxxxxxxxxxxx";
   chk chr($pfx)."abcdefghijklm";
}

ok (eval {sthaw undef; 1});
ok (!eval {sthaw "\x07"; 1});
ok (!defined sthaw sfreeze_best undef);

