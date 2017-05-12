use strict;

use Test;
use vars qw($loaded);
use Benchmark qw(timediff timestr);

BEGIN { plan tests => 10 }
END   { print "not ok 1\n" unless $loaded }

my $key       = pack "H*", '1234567890ABCDEFFEDCBA0987654321';
my $plaintext = "The quick brown fox jumps over the lazy dog.";

use Crypt::Twofish;
ok($loaded = 1);
ok(my $two = Crypt::Twofish->new("abcdefghijklmnop"));
ok("aaaabbbbccccdddd", $two->decrypt($two->encrypt("aaaabbbbccccdddd")));

foreach my $length (16, 24, 32) {
    my (@texts, @keys);

    my $key  = pack "H*", "00"x$length;
    my $text = pack "H*", "00"x16;

    for my $i (1..49) {
        $two  = Crypt::Twofish->new($key);
        $text = $two->encrypt($text);

        push @keys, $key;
        push @texts, $text;

        my $a = $texts[-2] || pack "H*", "00"x$length;
        my $b = $texts[-3] || pack "H*", "00"x$length;
        $key  = substr($a.$b, 0, $length);
    }

    if    ($length == 16) { ok(unpack("H*", $text), "5d9d4eeffa9151575524f115815a12e0"); }
    elsif ($length == 24) { ok(unpack("H*", $text), "e75449212beef9f4a390bd860a640941"); }
    elsif ($length == 32) { ok(unpack("H*", $text), "37fe26ff1cf66175f5ddf4c33b97a205"); }

    for (1..49) {
        $two  = Crypt::Twofish->new(pop(@keys));
        $text = $two->decrypt($text);
    }

    ok(unpack("H*", $text), "00"x16);
}

eval 'use Crypt::CBC';
if ($@) { print "skipping Crypt::CBC test\n"; }
else {
    print "trying CBC... ";
    my $c = Crypt::CBC->new($key, "Twofish") || die "$!\n";
    my $t = $c->encrypt_hex($plaintext);
    ok($plaintext, $c->decrypt_hex($t));
}

print "\nBenchmarks\n";
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEFFEDCBA9876543210";

        my $c = Crypt::Twofish->new($key);
        $c->encrypt($in);
    }

    my $t = Benchmark->new;

    print "Encrypting (10,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEFFEDCBA9876543210";

        my $c = Crypt::Twofish->new($key);
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (10,000 cycles, uncached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::Twofish->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEFFEDCBA9876543210";
        $c->encrypt($in);
    }

    my $t = Benchmark->new;

    print "Encrypting (10,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
{
    my $c = Crypt::Twofish->new($key);
    my $s = Benchmark->new;

    for (my $i = 0; $i < 10000; $i++) {
        my $in  = pack "H*", "0123456789ABCDEFFEDCBA9876543210";
        $c->decrypt($in);
    }

    my $t = Benchmark->new;

    print "Decrypting (10,000 cycles,   cached cipher): ",
          timestr(timediff($t, $s)), "\n";
}
