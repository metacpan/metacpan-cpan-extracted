use Test;
use Benchmark qw(timediff timestr);

BEGIN { plan tests => 4 }
END   { print "not ok 1\n" unless $loaded }

my $key       = pack "H*", '1234567890ABCDEFFEDCBA0987654321';
my $plaintext = "Network Security People Have A Strange Sense Of Humor";

use Crypt::NULL;
ok($loaded = 1);
ok($null = Crypt::NULL->new("abcdefghijklmnop"));
ok("aaaabbbb", $null->decrypt($null->encrypt("aaaabbbb")));

eval 'use Crypt::CBC';
if ($@) { print "skipping Crypt::CBC test\n"; }
else {
    print "trying CBC... ";
    my $c = Crypt::CBC->new($key, "NULL") || die "$!\n";
    my $t = $c->encrypt_hex($plaintext);
    ok($plaintext, $c->decrypt_hex($t));
}

print "\nBenchmarks\n";
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 20000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEF";

        my $c = Crypt::NULL->new($key);
        $c->encrypt($in);
    }

    my $t = Benchmark->new;

    print "Encrypting (20,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 20000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEF";

        my $c = Crypt::NULL->new($key);
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (20,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::NULL->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 50000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEF";
        $c->encrypt($in);
    }

    my $t = Benchmark->new;

    print "Encrypting (50,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::NULL->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 50000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEF";
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (50,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
