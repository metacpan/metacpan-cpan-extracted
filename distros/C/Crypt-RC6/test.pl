
BEGIN {
    $| = 1;
    print "1..13\n";
}

END {
    print "not ok 1\n" unless $loaded;
}

use Crypt::RC6;

$loaded = 1;
print "ok 1\n";

$i = 2;

while (<DATA>) {
   if (/key=(\S+)\sptext=(\S+)\sctext=(\S+)/) {
      my $key = pack "H*", $1;
      my $plaintext  = pack "H*", $2;
      my $ciphertext = pack "H*", $3;

      my $crypt = new Crypt::RC6 $key;

      my $ctext = $crypt->encrypt($plaintext);
      my $ptext = $crypt->decrypt($ctext);
      
      print $ctext eq $ciphertext ? "" : "not ", "ok " . $i++ . "\n";
      print $ptext eq $plaintext ? "" : "not ", "ok " . $i++ . "\n";
   }
}

__DATA__

key=00000000000000000000000000000000 ptext=00000000000000000000000000000000 ctext=8fc3a53656b1f778c129df4e9848a41e
key=0123456789abcdef0112233445566778 ptext=02132435465768798a9bacbdcedfe0f1 ctext=524e192f4715c6231f51f6367ea43f18
key=000000000000000000000000000000000000000000000000 ptext=00000000000000000000000000000000 ctext=6cd61bcb190b30384e8a3f168690ae82
key=0123456789abcdef0112233445566778899aabbccddeeff0 ptext=02132435465768798a9bacbdcedfe0f1 ctext=688329d019e505041e52e92af95291d4
key=0000000000000000000000000000000000000000000000000000000000000000 ptext=00000000000000000000000000000000 ctext=8f5fbd0510d15fa893fa3fda6e857ec2
key=0123456789abcdef0112233445566778899aabbccddeeff01032547698badcfe ptext=02132435465768798a9bacbdcedfe0f1 ctext=c8241816f0d7e48920ad16a1674e5d48
