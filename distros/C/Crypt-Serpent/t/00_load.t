
BEGIN {
    $| = 1;
    print "1..13\n";
}

END {
    print "not ok 1\n" unless $loaded;
}

use Crypt::Serpent;

$loaded = 1;
print "ok 1\n";

$i = 2;

while (<DATA>) {
   if (/key=(\S+)\sptext=(\S+)\sctext=(\S+)/) {
      my $key = pack "H*", $1;
      my $plaintext  = pack "H*", $2;
      my $ciphertext = pack "H*", $3;

      my $crypt = new Crypt::Serpent $key;

      my $ctext = $crypt->encrypt($plaintext);
      my $ptext = $crypt->decrypt($ctext);
      
      print $ctext eq $ciphertext ? "" : "not ", "ok " . $i++ . "\n";
      print $ptext eq $plaintext ? "" : "not ", "ok " . $i++ . "\n";
   }
}

__DATA__

key=00000000000000000000000000000080 ptext=00000000000000000000000000000000 ctext=ddd26b98a5ffd82c05345a9dadbfaf49
key=00080000000000000000000000000000 ptext=00000000000000000000000000000000 ctext=cfbd333352a34ed7f73d3e569d78c693
key=000000000000000000000000000000004000000000000000 ptext=00000000000000000000000000000000 ctext=53bd3e8475db67f72910b945bf8c768e
key=000000000000000000000000000000010000000000000000 ptext=00000000000000000000000000000000 ctext=deab7388a6f1c61d41e25a0d88f062c4
key=0000000000000000000000800000000000000000000000000000000000000000 ptext=00000000000000000000000000000000 ctext=ad4b018d50e3a28124a0a1259dc667d4
key=4000000000000000000000000000000000000000000000000000000000000000 ptext=00000000000000000000000000000000 ctext=eae1d405570174df7df2f9966d509159
