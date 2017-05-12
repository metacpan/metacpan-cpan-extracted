use strict;

use Test;
use vars qw($loaded);
use Benchmark qw(timediff timestr);

BEGIN { plan tests => 6 }
END   { print "not ok 1\n" unless $loaded }

my $key       = pack "H*", '1234567890ABCDEFFEDCBA0987654321'x2;
my $plaintext = "The quick brown fox jumps over the lazy dog.";

use Crypt::GOST;
ok($loaded = 1);
ok(my $gost = Crypt::GOST->new("abcdefghijklmnop"x2));
ok("aaaabbbb", $gost->decrypt($gost->encrypt("aaaabbbb")));
ok(my $old = Crypt::GOST->new);
$old->generate_sbox($key); $old->generate_keys($key);
ok(
    # The old SSdecrypt used to return spurious padding material.
    substr($old->SSdecrypt($old->SScrypt($plaintext)), 0, length $plaintext),
    $plaintext
);

eval 'use Crypt::CBC';
if ($@) { print "skipping Crypt::CBC test\n"; }
else {
    print "trying CBC... ";
    my $c = Crypt::CBC->new($key, "GOST") || die "$!\n";
    my $t = $c->encrypt_hex($plaintext);
    ok($plaintext, $c->decrypt_hex($t));
}

print "\nBenchmarks\n";
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $c  = Crypt::GOST->new($key);
        my $in = pack "H*", "1234567890ABCDEF";
        $c->encrypt($in);
    }

    my $t = Benchmark->new;

    print "Encrypting (10,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $c  = Crypt::GOST->new($key);
        my $in = pack "H*", "1234567890ABCDEF";
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (10,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::GOST->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $in = pack "H*", "1234567890ABCDEF";
        $c->encrypt($in);
    }

    my $t = Benchmark->new;

    print "Encrypting (10,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::GOST->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $in = pack "H*", "1234567890ABCDEF";
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (10,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
