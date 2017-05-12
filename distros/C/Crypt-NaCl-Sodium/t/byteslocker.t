
use strict;
use warnings;
use Test::More;

use Crypt::NaCl::Sodium qw(:utils);

$Data::BytesLocker::DEFAULT_LOCKED = 1;

my $crypto_secretbox = Crypt::NaCl::Sodium->secretbox();

for my $i ( 1 .. 2 ) {
    my $key = $crypto_secretbox->keygen();
    isa_ok($key, "Data::BytesLocker");
    ok($key->is_locked, "locked by default");
    eval {
        my $skey = "$key";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");

    ok($key->unlock, "...but can unlock");

    like($key->to_hex, qr/^[a-f0-9]{64}$/, "->to_hex");
    my $skey = $key;
    isa_ok($skey, "Data::BytesLocker");

    eval { $key lt $skey ? 1 : 0 };
    like($@, qr/Operation "lt" is not supported/, 'Operation "lt" is not supported');
    eval { $key le $skey ? 1 : 0 };
    like($@, qr/Operation "le" is not supported/, 'Operation "le" is not supported');

    eval { $key gt $skey ? 1 : 0 };
    like($@, qr/Operation "gt" is not supported/, 'Operation "gt" is not supported');
    eval { $key ge $skey ? 1 : 0 };
    like($@, qr/Operation "ge" is not supported/, 'Operation "ge" is not supported');

    eval { $key .= "aaa" };
    like($@, qr/Operation "=" is not supported/, 'Operation "=" is not supported');

    my $key_str = "$key";
    is($key_str, $key, "stringification works");
    is(ref $key_str, '', "stringified object is plain scalar");

    my $key_bytes = $key->bytes;
    is($key_str, $key_bytes, "->bytes returns protected bytes");
    is(ref $key_bytes, '', "...and is plain scalar");

    ok($key eq $skey, "key -eq skey");
    ok(! ( $key ne $skey), "key -ne skey");
    ok($key, "-bool key");


    my $key_aaa = $key . "aaa";
    isa_ok($key_aaa, "Data::BytesLocker");
    eval {
        my $skey = "$key_aaa";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "concat result locked");
    ok($key_aaa->unlock, "...but can unlock");

    is($key_aaa, "${key_str}aaa", "key . STR");

    my $aaa_key = "aaa" . $key;
    isa_ok($aaa_key, "Data::BytesLocker");
    eval {
        my $skey = "$aaa_key";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "concat result locked");
    ok($aaa_key->unlock, "...but can unlock");

    is($aaa_key, "aaa${key_str}", "STR . key");

    my $key_x_5 = $key x 5;
    isa_ok($key_x_5, "Data::BytesLocker");
    eval {
        my $skey = "$key_x_5";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "concat result locked");
    ok($key_x_5->unlock, "...but can unlock");

    is($key_x_5, "${key_str}${key_str}${key_str}${key_str}${key_str}", "key x 5");

    $key = "1234";

    ok(! ref $key, "key after assignment not longer an object");
}

my $locker1 = Data::BytesLocker->new("readonly protected data");
isa_ok($locker1, "Data::BytesLocker");
eval {
    my $s = "$locker1";
};
like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");
ok($locker1->unlock, "...but can unlock");
is($locker1->to_hex, bin2hex("readonly protected data"), "->to_hex eq bin2hex");
is($locker1->bytes, "readonly protected data", "data is accessible");

eval {
    my $locker2 = Data::BytesLocker->new("readonly protected data", wipe => 1 );
};
like($@, qr/^Modification of a read-only value attempted/, "Cannot wipe readonly data");

my $var = "protected data";
my $var_len = length($var);
my $locker3 = Data::BytesLocker->new($var, wipe => 1 );
isa_ok($locker3, "Data::BytesLocker");
eval {
    my $s = "$locker3";
};
like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");
ok($locker3->unlock, "...but can unlock");
is($locker3->to_hex, bin2hex("protected data"), "->to_hex eq bin2hex");
is($var, "\x0" x $var_len, "orginal variable wiped out");
is($locker3->length, $var_len, "->length works");

{
    $Data::BytesLocker::DEFAULT_LOCKED = 0;

    my $unlocked = Data::BytesLocker->new("not locked");
    ok(! $unlocked->is_locked, "not locked by default");
    is($unlocked, "not locked", "...and can be accessed");
    ok($unlocked->lock, "...but can be locked");
    eval {
        my $str = "$unlocked";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");
}
{
    local $Data::BytesLocker::DEFAULT_LOCKED = 1;

    my $locked = Data::BytesLocker->new("is locked");
    ok($locked->is_locked, "now locked by default");
    eval {
        my $str = "$locked";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");
    ok($locked->unlock, "...but can be unlocked");
    is($locked, "is locked", "...and can be accessed");
}
{
    my $unlocked = Data::BytesLocker->new("fall back to not locked");
    ok(! $unlocked->is_locked, "fall back to not locked by default");
    is($unlocked, "fall back to not locked", "...and can be accessed");
    ok($unlocked->lock, "...but can be locked");
    eval {
        my $str = "$unlocked";
    };
    like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");
}

{ # compare
    my $a = Data::BytesLocker->new("abc");
    my $b = "abC";

    ok( ! $a->memcmp($b), "memcmp: 'abc' and 'abC' differ");

    for (1 .. 1000) {
        my $bin_len = 1 + random_number(1000);
        my $buf1 = random_bytes($bin_len);
        my $buf2 = random_bytes($bin_len);
        my $buf1_rev = Data::BytesLocker->new(scalar reverse $buf1);
        my $buf2_rev = reverse $buf2;
        ok($buf1_rev->memcmp($buf2_rev, $bin_len) * $buf1->compare($buf2, $bin_len) >= 0,
            "compare correct with length=$bin_len");
        is($buf2->compare($buf2->bytes, $bin_len), 0, "compare() equality correct with length=$bin_len");
    }

    eval {
        my $res = $a->memcmp("abcde");
    };
    like($@, qr/^Variables of unequal length/, "memcmp: variables of unequal length cannot be compared without length specified");

    eval {
        my $res = $a->compare("ab");
    };
    like($@, qr/^Variables of unequal length/, "compare: variables of unequal length cannot be compared without length specified");


    ok( $a->memcmp("abc", 2), "memcmp: first two chars are equal");
    is( $a->compare("abc", 2), 0, "compare: first two chars are equal");

    eval {
        my $res = $a->memcmp("abcd", 4);
    };
    like($@, qr/^The data is shorter/, "memcmp: length=4 > ab");

    eval {
        my $res = $a->compare("abcd", 4);
    };
    like($@, qr/^The data is shorter/, "compare: length=4 > ab");

    eval {
        my $res = $a->memcmp("ab", 3);
    };
    like($@, qr/^The argument is shorter/, "memcmp: length=3 > ab");


    eval {
        my $res = $a->compare("ab", 3);
    };
    like($@, qr/^The argument is shorter/, "compare: length=3 > ab");
}

{ # sodium_increment
    my $nonce = Data::BytesLocker->new(
        scalar("\xff" x 6) . scalar("\xfe" x (24 - 6))
    );
    my $next_nonce = $nonce->increment();
    is($next_nonce->to_hex, "000000000000fffefefefefefefefefefefefefefefefefe", "increment() (xFF x 6)");

    $nonce = Data::BytesLocker->new(
        scalar("\xff" x 10) . scalar("\xfe" x (24 - 10))
    );
    $next_nonce = $nonce->increment();
    is($next_nonce->to_hex, "00000000000000000000fffefefefefefefefefefefefefe", "increment() (xFF x 10)");


    $nonce = Data::BytesLocker->new(
        scalar("\xff" x 22) . scalar("\xfe" x (24 - 22))
    );
    $next_nonce = $nonce->increment();
    is($next_nonce->to_hex, "00000000000000000000000000000000000000000000fffe", "increment() (xFF x 22)");
}
{ # sodium_add
    my $bin_len = random_number(1_000);
    my $buf1 = random_bytes($bin_len);
    my $buf2 = $buf1->clone;
    my $buf_add = Data::BytesLocker->new(scalar("\0" x $bin_len));
    ok($buf_add->is_zero, "is_zero detects null data");
    my $j = random_number(10_000);
    for ( my $i = 0; $i < $j; $i++ ) {
        $buf1 = $buf1->increment();
        $buf_add = $buf_add->increment();
    }
    ok(!$buf_add->is_zero, "is_zero detects not null data");
    $buf2 = $buf2->add($buf_add);
    ok($buf2->compare($buf1) == 0, "add(\$num) result as expected");

    my $nonce = Data::BytesLocker->new(
        scalar("\xff" x 6) . scalar("\xfe" x (24 - 6))
    );
    $nonce = $nonce->add($nonce, 7);
    $nonce = $nonce->add($nonce, 8);
    is($nonce->to_hex, "fcfffffffffffbfdfefefefefefefefefefefefefefefefe",
        "add(\$nonce, 7) followed by add(\$nonce, 8)");

    $nonce = Data::BytesLocker->new(
        scalar("\xff" x 10) . scalar("\xfe" x (24 - 10))
    );
    $nonce = $nonce->add($nonce, 11);
    $nonce = $nonce->add($nonce, 12);

    is($nonce->to_hex, "fcfffffffffffffffffffbfdfefefefefefefefefefefefe",
        "add(\$nonce, 11) followed by add(\$nonce, 12)");

    $nonce = Data::BytesLocker->new(
        scalar("\xff" x 22) . scalar("\xfe" x (24 - 22))
    );
    $nonce = $nonce->add($nonce, 23);
    $nonce = $nonce->add($nonce, 24);
    is($nonce->to_hex, "fcfffffffffffffffffffffffffffffffffffffffffffbfd",
        "add(\$nonce, 23) followed by add(\$nonce, 24)");
}
done_testing();

