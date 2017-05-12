BEGIN { $| = 1; print "1..1621\n"; }

use Crypt::Ed25519;

# test vectors generated from ed25519's website sign.input via extract-sign.input

my @tv = unpack "(a32 a32 a64 w/a*)*", do {
   open my $fh, "<:raw", "t/sign.input"
      or die "t/sign.input: $!";
   local $/;
   readline $fh
};

print "ok 1\n";

my $i = 1;

while (@tv) {
   my ($seed, $pub, $s, $m) = splice @tv, -4, 4;

   my $pub_ = Crypt::Ed25519::eddsa_public_key $seed;
   print $pub_ eq $pub ? "" : "not ", "ok ", ++$i, "\n";

   my ($pub__, $priv) = Crypt::Ed25519::generate_keypair $seed;
   print $pub_ eq $pub__ ? "" : "not ", "ok ", ++$i, "\n";

   my $s_ = Crypt::Ed25519::eddsa_sign $m, $pub, $seed;
   print $s eq $s_ ? "" : "not ", "ok ", ++$i, "\n";

   my $s__ = Crypt::Ed25519::sign $m, $pub, $priv;
   print $s eq $s_ ? "" : "not ", "ok ", ++$i, "\n";

   my $valid = Crypt::Ed25519::eddsa_verify $m, $pub, $s;
   print $valid ? "" : "not ", "ok ", ++$i, "\n";

   my $notvalid = !Crypt::Ed25519::eddsa_verify "x$m", $pub, $s;
   print $notvalid ? "" : "not ", "ok ", ++$i, "\n";
}

