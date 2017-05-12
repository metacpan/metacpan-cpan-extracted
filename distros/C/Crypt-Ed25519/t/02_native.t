BEGIN { $| = 1; print "1..1537\n"; }

use Crypt::Ed25519;

print "ok 1\n";

my $i = 1;

for (0..511) {
   my $secret = Crypt::Ed25519::eddsa_secret_key;
   my ($pub, $priv) = Crypt::Ed25519::generate_keypair $secret;
   my $m = Crypt::Ed25519::eddsa_secret_key;

   $m = substr "$m$m", 0, rand 64;

   my $s = Crypt::Ed25519::sign $m, $pub, $priv;

   my $s2 = Crypt::Ed25519::eddsa_sign $m, $pub, $secret;
   print $s eq $s2 ? "" : "not ", "ok ", ++$i, "\n";

   my $valid = Crypt::Ed25519::verify $m, $pub, $s;
   print $valid ? "" : "not ", "ok ", ++$i, "\n";

   my $notvalid = !Crypt::Ed25519::verify "x$m", $pub, $s;
   print $notvalid ? "" : "not ", "ok ", ++$i, "\n";
}

