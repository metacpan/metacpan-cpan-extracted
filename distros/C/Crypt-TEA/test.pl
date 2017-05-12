use strict;

use Test;
use vars qw($loaded);
use Benchmark qw(timediff timestr);

BEGIN { plan tests => 6 }
END   { print "not ok 1\n" unless $loaded }

my $key       = pack "H*", '1234567890ABCDEFFEDCBA0987654321';
my $plaintext = "The quick brown fox jumps over the lazy dog.";

use Crypt::TEA;
ok($loaded = 1);
ok(my $tea = Crypt::TEA->new("abcdefghijklmnop"));
ok("aaaabbbb", $tea->decrypt($tea->encrypt("aaaabbbb")));

eval 'use Crypt::CBC';
if ($@) { print "skipping Crypt::CBC test\n"; }
else {
    print "trying CBC... ";
    my $c = Crypt::CBC->new($key, "TEA") || die "$!\n";
    my $t = $c->encrypt_hex($plaintext);
    ok($plaintext, $c->decrypt_hex($t));
}

print "\nBenchmarks\n";
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 20000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEF";

        my $c = Crypt::TEA->new($key);
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

        my $c = Crypt::TEA->new($key);
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (20,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::TEA->new($key);
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
    my $c = Crypt::TEA->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 50000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEF";
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (50,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
