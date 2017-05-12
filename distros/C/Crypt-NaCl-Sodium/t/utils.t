
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

my $bin = 'ABC';
my $hex = bin2hex($bin);
is($hex, "414243", "bin2hex(ABC)");
my $bin2 = hex2bin($hex);
is($bin2, $bin, "hex2bin(hex)");

my @hex = (
    '414243',
    '41 42 43',
    '41:4243',
);

for my $hex ( @hex ) {
    my $bin3 = hex2bin( $hex, ignore => ': ' );
    is($bin3, $bin, "hex2bin($hex, ignore => ': ')");
}
is(hex2bin( '414243', max_len => 2 ), 'AB',
    "hex2bin(414243, max_len => 2) == AB");
is(hex2bin( '41 42 43', max_len => 2 ), 'A',
    "hex2bin(41 42 43, max_len => 2) == A");
is(hex2bin( '41:42:43', ignore => ':', max_len => 2 ), 'AB',
    "hex2bin(41:42:43, ignore => ':', max_len => 2) == AB");
is(hex2bin( '41:42:43', max_len => 2 ), 'A',
    "hex2bin(41:42:43, max_len => 2) == A");

my ($a, $b) = ( "abc", "abC");

ok( ! memcmp($a, $b), "memcmp: 'abc' and 'abC' differ");

for (1 .. 1000) {
    my $bin_len = 1 + random_number(1000);
    my $buf1 = random_bytes($bin_len);
    my $buf2 = random_bytes($bin_len);
    my $buf1_rev = reverse $buf1;
    my $buf2_rev = reverse $buf2;
    ok(memcmp($buf1_rev, $buf2_rev, $bin_len) * compare($buf1, $buf2, $bin_len) >= 0,
        "compare correct with length=$bin_len");
    my $buf2c = $buf2->bytes;
    is(compare($buf2c, $buf2, $bin_len), 0, "compare() equality correct with length=$bin_len");
}

eval {
    my $res = memcmp("ab", "abc");
};
like($@, qr/^Variables of unequal length/, "memcmp: variables of unequal length cannot be compared without length specified");

eval {
    my $res = compare("ab", "abc");
};
like($@, qr/^Variables of unequal length/, "compare: variables of unequal length cannot be compared without length specified");


ok( memcmp("ab", "abc", 2), "memcmp: first two chars are equal");
is( compare("ab", "abc", 2), 0, "compare: first two chars are equal");

eval {
    my $res = memcmp("ab", "abc", 3);
};
like($@, qr/^First argument is shorter/, "memcmp: length=3 > ab");

eval {
    my $res = compare("ab", "abc", 3);
};
like($@, qr/^First argument is shorter/, "compare: length=3 > ab");

eval {
    my $res = memcmp("abcd", "abc", 4);
};
like($@, qr/^Second argument is shorter/, "memcmp: length=4 > abc");


eval {
    my $res = compare("abcd", "abc", 4);
};
like($@, qr/^Second argument is shorter/, "compare: length=4 > abc");

memzero($a, $b);
is(length($a), 3, "memzero(a) preserves length");
like($a, qr/^\0{3}$/, "...and replaces with null bytes");
is(length($b), 3, "memzero(a) preserves length");
like($b, qr/^\0{3}$/, "...and replaces with null bytes");

for my $i ( 0 .. 10 ) {
    my $max = $i ** 10;
    for ( 1 .. 10 ) {
        my $n;
        if ( $max && $max % 3 == 0 ) {
            $n = random_number( $max );
            ok($n < $max, "$n < $max generated");
        } else {
            $n = random_number();
            ok($n, "$n without upper bound generated");
        }
    }
}

my $rbytes = random_bytes(10);
ok($rbytes, "got random bytes");
is(length($rbytes), 10, "...and 10 as requested");

eval {
    my $t = random_bytes(0);
};
like($@, qr/^Invalid length/, "at least 1 random byte needs to be requested");


my $nonce = "\0" x 24;
increment($nonce);
is(bin2hex($nonce), "010000000000000000000000000000000000000000000000",
    "incremented 000...");

$nonce = chr(0xff) x 24;
increment($nonce);
is(bin2hex($nonce), "000000000000000000000000000000000000000000000000",
    "incremented fff...");

substr($nonce, 1, 1, chr(1));
increment($nonce);
is(bin2hex($nonce), "010100000000000000000000000000000000000000000000",
    "incremented 0001000...");

substr($nonce, 1, 1, chr(0));
increment($nonce);
is(bin2hex($nonce), "020000000000000000000000000000000000000000000000",
    "incremented 01000...");

substr($nonce, 0, 1, chr(0xff));
substr($nonce, 2, 1, chr(0xff));
increment($nonce);
is(bin2hex($nonce), "0001ff000000000000000000000000000000000000000000",
    "incremented ff00ff000...");

done_testing();

