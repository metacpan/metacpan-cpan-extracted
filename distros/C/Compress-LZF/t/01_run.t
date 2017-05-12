BEGIN { $| = 1; print "1..29\n"; }
END {print "not ok 1\n" unless $loaded;}
use Compress::LZF;
$loaded = 1;
print "ok 1\n";

my $tst = 2;

for ("",
     "x" x 10000,
     rand().rand().rand() x 10000,
     join "", map rand, 1..10000
     ) {
   my $compr1 = compress $_;
   my $compr2 = compress $compr1;
   my $uncompr1 = decompress $compr1;
   my $compr3 = compress $_;
   my $uncompr2 = decompress $compr2;
   my $uncompr3 = decompress $uncompr2;

   print length($compr1) <= length($_)+1 ? "" : "not ", "ok ", $tst++, "\n";
   print length($compr2) <= length($compr1)+1 ? "" : "not ", "ok ", $tst++, "\n";
   print length($compr3) <= length($_)+1 ? "" : "not ", "ok ", $tst++, "\n";
   print $compr1 eq $compr3 ? "" : "not ", "ok ", $tst++, "\n";
   print $uncompr1 eq $_ ? "" : "not ", "ok ", $tst++, "\n";
   print $uncompr2 eq $compr1 ? "" : "not ", "ok ", $tst++, "\n";
   print $uncompr3 eq $_ ? "" : "not ", "ok ", $tst++, "\n";
}
