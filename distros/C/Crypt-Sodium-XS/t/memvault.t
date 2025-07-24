use strict;
use warnings;
use Test::More;
use MIME::Base64 'encode_base64';
use File::Temp;

use Crypt::Sodium::XS::ProtMem ':constants';
use Crypt::Sodium::XS::Util 'sodium_random_bytes';
use Crypt::Sodium::XS::secretbox qw/secretbox_KEYBYTES secretbox_keygen/;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

# for older perl with older MIME::Base64:
sub encode_base64url { (my $str = encode_base64($_[0], '')) =~ tr,+/=,-_,d; $str }

my @mv_datas = (
  "this is a string of things.",
  "so is \x{ef}\x{bb}\x{bf} this one", # utf-8 encoded U+FFEF
);


for my $mv_data (@mv_datas) {
  my $mv = Crypt::Sodium::XS::MemVault->new($mv_data);
  isa_ok($mv, "Crypt::Sodium::XS::MemVault");
  ok($mv->is_locked, "locked by default");
  is($mv->length, length($mv_data), "correct length");
  eval { my $x = "$mv"; };
  like($@, qr/Unlock MemVault object before/, "cannot stringify locked bytes");
  eval { my $x = $mv->to_bytes; };
  like($@, qr/Unlock MemVault object before/, "cannot to_bytes locked bytes");
  eval { my $x = $mv->index("dangerous"); };
  like($@, qr/Unlock MemVault object before/, "cannot index locked bytes");
  my $mv_clone = $mv->clone;
  isa_ok($mv_clone, "Crypt::Sodium::XS::MemVault");
  ok($mv_clone->is_locked, "clone of locked MemVault is_locked");
  $mv->unlock;
  ok(!$mv->is_locked, "unlocked MemVault !is_locked");
  ok(!$mv->clone->is_locked, "clone of unlocked MemVault !is_locked");
  like($mv->to_hex->unlock, qr/^[a-f0-9]+$/, "->to_hex format");
  ok($mv->lock->is_locked, "locking returns the locked MemVault");

  ok($mv eq $mv_data, "mv eq mv_data");
  ok($mv == $mv_data, "mv == mv_data");
  ok($mv_data eq $mv, "mv_data eq mv");
  ok($mv_data == $mv, "mv_data == mv");
  ok($mv eq $mv_clone, "mv eq clone");
  ok($mv == $mv_clone, "mv == clone");
  ok(!($mv ne $mv_clone), "! mv ne clone");
  ok(!($mv != $mv_clone), "! mv != clone");
  ok($mv, "boolean mv");

  $mv->unlock;

  my $mv_str = "$mv";
  ok($mv_str, "stringification works");
  is(ref $mv_str, '', "stringified object is not a ref");
  is($mv_str, $mv_data, "stringified object correct bytes");
  $mv_str = $mv->to_bytes;
  ok($mv_str, "to_bytes works");
  is(ref $mv_str, '', "to_bytes object is not a ref");
  is($mv_str, $mv_data, "to_bytes object correct bytes");

  is($mv->to_hex, unpack("H*", $mv_data), "->to_hex eq unpack");
  ok($mv eq Crypt::Sodium::XS::MemVault->new_from_hex($mv->to_hex), "hex roundtripped");
  is($mv->to_base64, encode_base64url($mv_data), "->to_base64 eq MIME::Base64");
  ok($mv eq Crypt::Sodium::XS::MemVault->new_from_base64($mv->to_base64), "base64 roundtripped");

  # should test on locked memvault as well, ensure result is locked
  is($mv->extract(3), substr($mv_str, 3), "extract with +offset");
  is($mv->extract(0, 3), substr($mv_str, 0, 3), "extract with +offset and +length");
  is($mv->extract(-5), substr($mv_str, -5), "extract -offset");
  is($mv->extract(-5, 3), substr($mv_str, -5, 3), "extract -offset and +length");
  is($mv->extract(3, -3), substr($mv_str, 3, -3), "extract +offset and -length");
  is($mv->extract(-5, -3), substr($mv_str, -5, -3), "extract -offset and -length");
  is($mv->extract(0, $mv->length + 1), substr($mv_str, 0, $mv->length + 1),
    "+length too big");
  is($mv->extract(0, 0 - $mv->length - 1), substr($mv_str, 0, 0 - $mv->length - 1),
    "-length too small");
  is($mv->extract(3, $mv->length + 1), substr($mv_str, 3, $mv->length + 1),
    "+offset +length too big");
  is($mv->extract(3, 0 - $mv->length - 1), substr($mv_str, 3, 0 - $mv->length - 1),
    "+offset -length too small");
  is($mv->extract(-3, $mv->length + 1), substr($mv_str, -3, $mv->length + 1),
    "-offset +length too big");
  is($mv->extract(-3, 0 - $mv->length - 1), substr($mv_str, -3, 0 - $mv->length - 1),
    "-offset -length too small");
  eval { $mv->extract(100) };
  like($@, qr/Invalid offset/, "extract invalid offset (100)");
  eval { $mv->extract(-100) };
  like($@, qr/Invalid offset/, "extract invalid offset (-100)");
  is($mv->extract(0, -3), substr($mv_str, 0, -3), "extract negative length");

  is($mv->index("t"), index($mv_str, "t"), "index single char");
  is($mv->index("this"), index($mv_str, "this"), "index word");
  is($mv->index("t", 5), index($mv_str, "t", 5), "index single char with offset");
  is($mv->index("thi", 9), index($mv_str, "thi", 9), "index word with offset");
  is($mv->index("t", 999), index($mv_str, "t", 999), "index single char offset out of range");

  $mv->lock;

  my $mv_aaa = $mv . "aaa";
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok($mv_aaa->is_locked, "overloaded .: MV . SV locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "overloaded .: MV . SV, correct result");
  is($mv->to_hex->unlock, unpack("H*", $mv_data), "overloaded .: MV . SV did not mutate");
  $mv_aaa = $mv->concat("aaa");
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok($mv_aaa->is_locked, "concat: MV concat SV locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "concat: MV concat SV, correct result");
  is($mv->to_hex->unlock, unpack("H*", $mv_data), "concat: did not mutate");

  $mv_clone = $mv->clone;
  $mv_clone .= "aaa";
  ok($mv_clone->is_locked, "overloaded .=: MV .= SV locked, result locked");
  is($mv_clone->to_hex->unlock, unpack("H*", $mv_data . "aaa"), "overloaded .=: correct results");
  $mv_clone = $mv->clone;
  $mv_clone->concat_inplace("aaa");
  ok($mv_clone->is_locked, "concat_inplace: MV concat_inplace SV locked, result locked");
  is($mv_clone->to_hex->unlock, unpack("H*", $mv_data . "aaa"), "concat_inplace: correct results");

  my $aaa_key = "aaa" . $mv;
  isa_ok($aaa_key, "Crypt::Sodium::XS::MemVault");
  ok($aaa_key->is_locked, "overloaded .: SV . MV locked, result locked");
  is($aaa_key->to_hex->unlock, unpack("H*", "aaa" . $mv_data),
     "overloaded .: SV . MV, correct result");
  is($mv->to_hex->unlock, unpack("H*", $mv_data), "overloaded .: SV . MV did not mutate");

  $mv_aaa = $mv . Crypt::Sodium::XS::MemVault->new("aaa");
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok($mv_aaa->is_locked, "overloaded .: MV . MV both locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "overloaded .: MV . MV both locked, correct result");
  is($mv->to_hex->unlock, unpack("H*", $mv_data), "overloaded .: MV . MV did not mutate");

  $mv_aaa = $mv . Crypt::Sodium::XS::MemVault->new("aaa")->unlock;
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok($mv_aaa->is_locked, "overloaded .: MV . MV one locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "overloaded .: MV . MV one locked, correct result");

  $mv_aaa = $mv->clone->unlock . Crypt::Sodium::XS::MemVault->new("aaa")->unlock;
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok(!$mv_aaa->is_locked, "overloaded .: MV . MV none locked, result unlocked");
  is($mv_aaa->to_hex, unpack("H*", $mv_data . "aaa"),
     "overloaded .: MV . MV none locked, correct result");

  my $mv_x_5 = $mv x 5;
  isa_ok($mv_x_5, "Crypt::Sodium::XS::MemVault");
  ok($mv_x_5->is_locked, "repitition of locked MemVault is locked");

  is($mv_x_5->to_hex->unlock,
    unpack("H*", "${mv_data}${mv_data}${mv_data}${mv_data}${mv_data}"), "mv x 5");
}

{ # compare
  my $x = Crypt::Sodium::XS::MemVault->new("abc")->unlock;
  my $y = "abC";
  my $z = Crypt::Sodium::XS::MemVault->new("abC")->unlock;

  ok($x->memcmp("abc"), "memcmp: MV to same SV are equal");
  ok(!$x->compare("abc"), "compare: MV to same SV are equal");
  ok(!$x->memcmp($y), "memcmp: 'MV to different SV differ");
  ok($x->compare($y), "compare: 'MV to different SV differ");
  ok(!$x->memcmp($z), "memcmp: MV to different MV differ");
  ok($x->compare($z), "compare: MV to different MV differ");
  ok($x->memcmp("abcdefghi", 2), "memcmp: MV to SV with length are equal");
  ok(!$x->compare("abcdefghi", 2), "compare: MV to SV with length are equal");
  ok(!$x->memcmp("zbc", 2), "memcmp: MV to different SV with length differ");
  ok($x->compare("zbc", 2), "compare: MV to different SV with length differ");

  is($x->compare($y), 1, "compare: MV to lesser SV is 1");
  is($x->compare("zbc"), -1, "compare: MV to greater SV is -1");
  is($x->compare($z), 1, "compare: MV to lesser MV is 1");
  $y = Crypt::Sodium::XS::MemVault->new("zbc")->unlock;
  is($x->compare($y), -1, "compare: MV to greater MV is -1");

  ok($x > "abC", "overloaded >: MV to lesser SV is true");
  ok($x >= "abC", "overloaded >=: MV to lesser SV is true");
  ok(!($x < "abC"), "overloaded <: MV to lesser SV is false");
  ok(!($x <= "abC"), "overloaded <=: MV to lesser SV is false");
  ok("abC" < $x, "overloaded <: SV to lesser MV is true");
  ok("abC" <= $x, "overloaded <=: SV to lesser MV is true");
  ok(!("abC" > $x), "overloaded >: SV to lesser MV is false");
  ok(!("abC" >= $x), "overloaded >=: SV to lesser MV is false");
  ok($x < $y, "overloaded <: MV to greater MV is true");
  ok($x <= $y, "overloaded <=: MV to greater MV is true");
  ok(!($x > $y), "overloaded >: MV to lesser MV is false");
  ok(!($x >= $y), "overloaded >=: MV to lesser MV is false");
  ok($y > $x, "overloaded >: MV to greater MV is true");
  ok($y >= $x, "overloaded >=: MV to greater MV is true");
  ok(!($y < $x), "overloaded <: MV to greater MV is false");
  ok(!($y <= $x), "overloaded <=: MV to greater MV is false");
  ok($x < "zbc", "overloaded <: SV to lesser MV is true");
  ok($x <= "zbc", "overloaded <=: SV to lesser MV is true");
  ok(!($x > "zbc"), "overloaded >: SV to lesser MV is false");
  ok(!($x >= "zbc"), "overloaded >=: SV to lesser MV is false");
  ok("abd" > $x, "overloaded >: MV to lesser SV is true");
  ok("abd" >= $x, "overloaded >=: MV to lesser SV is true");
  ok(!("abd" < $x), "overloaded <: MV to lesser SV is false");
  ok(!("abd" <= $x), "overloaded <=: MV to lesser SV is false");

  $y->lock;
  eval { $y->compare("abc") };
  like($@, qr/Unlock MemVault object before/, "cannot compare locked mv invocant");
  eval { $z->compare($y); };
  like($@, qr/Unlock MemVault object before/, "cannot compare locked mv arg");
  eval { my $junk = $y > "abc" };
  like($@, qr/Unlock MemVault object before/, "overloaded >: cannot compare locked mv");
  eval { my $junk = "abc" > $y };
  like($@, qr/Unlock MemVault object before/, "overloaded >: cannot compare locked mv swap");
  eval { my $junk = $z > $y };
  like($@, qr/Unlock MemVault object before/, "overloaded >: cannot compare locked mv to mv");
  eval { my $junk = $y > $z };
  like($@, qr/Unlock MemVault object before/, "overloaded >: cannot compare locked mv to mv swap");

  $y = Crypt::Sodium::XS::MemVault->new("abcdefghi")->unlock;
  $z = Crypt::Sodium::XS::MemVault->new("zbcdef")->unlock;
  ok($x->memcmp($y, 2), "memcmp: MV to MV with length are equal");
  ok(!$x->compare($y, 2), "compare: MV to MV with length are equal");
  ok(!$x->memcmp($z, 2), "memcmp: MV to different MV with length differ");
  ok($x->compare($z, 2), "compare: MV to different MV with length differ");

  eval { my $res = $x->memcmp("abcde"); };
  like($@, qr/Variables of unequal size/,
       "memcmp of unequal length must specify size");
  eval { my $res = $x->compare("ab"); };
  like($@, qr/Variables of unequal size/,
       "compare of unequal length must specify size");
  eval { my $res = $x->memcmp("abcd", 4); };
  like($@, qr/The argument \(left\) is shorter/, "memcmp: length=4 > ab");
  eval { my $res = $x->compare("abcd", 4); };
  like($@, qr/The argument \(left\) is shorter/, "compare: length=4 > ab");
  eval { my $res = $x->memcmp("ab", 3); };
  like($@, qr/The argument \(right\) is shorter/, "memcmp: length=3 > ab");
  eval { my $res = $x->compare("ab", 3); };
  like($@, qr/The argument \(right\) is shorter/, "compare: length=3 > ab");

  for (1 .. 1000) { # probably a bit excessive...
    my $bin_len = 1 + int(rand(1000));
    my $buf1 = sodium_random_bytes(1000);
    my $buf2 = sodium_random_bytes(1000);
    my $mv1 = Crypt::Sodium::XS::MemVault->new($buf1)->unlock;
    my $mv2 = Crypt::Sodium::XS::MemVault->new($buf2)->unlock;
    ok($mv1->memcmp($buf1, $bin_len), "memcmp: MV to equal SV with length");
    ok(!$mv1->compare($buf1, $bin_len), "compare: MV to equal SV with length");
    ok($mv1->memcmp($mv1->clone, $bin_len), "memcmp: MV to clone MV with length");
    ok(!$mv1->compare($mv1->clone, $bin_len), "compare: MV to clone MV with length");
    if ($bin_len > 16) { # very unlikely 128 bits identical
      ok(!$mv1->memcmp($buf2, $bin_len), "memcmp: MV to different SV with length");
      ok($mv1->compare($buf2, $bin_len), "compare: MV to different SV with length");
      ok(!$mv1->memcmp($mv2, $bin_len), "memcmp: MV to different MV with length");
      ok($mv1->compare($mv2, $bin_len), "compare: MV to different MV with length");
    }
  }
}

my $mv = Crypt::Sodium::XS::MemVault->new("\xff\xff\xff")->unlock;
my $mv2 = $mv->bitwise_and("\x00\x00\x00")->unlock;
is($mv2->to_hex, "000000", "bitwise and");
$mv = Crypt::Sodium::XS::MemVault->new("\x01\x02\x03")->unlock;
$mv->bitwise_and_equals("\x04\x05\x06");
is($mv->to_hex, "000002", "bitwise and-equals");
$mv = Crypt::Sodium::XS::MemVault->new("\xaa\xbb\xcc")->unlock;
$mv2 = $mv & "\xdd\xee\xff";
is($mv->to_hex, "aabbcc", "overloaded & does not mutate");
is($mv2->to_hex, "88aacc", "overloaded & result");
$mv2 = "\xff\x00\xff" & $mv;
is($mv2->to_hex, "aa00cc", "overloaded & result, reverse args");
$mv &= "\xff\x00\xff";
is($mv->to_hex, "aa00cc", "overloaded &= mutates");

$mv = Crypt::Sodium::XS::MemVault->new("\xff\xff\xff")->unlock;
$mv2 = $mv->bitwise_or("\x00\x00\x00");
is($mv2->to_hex, "ffffff", "bitwise or");
$mv = Crypt::Sodium::XS::MemVault->new("\x01\x02\x03")->unlock;
$mv->bitwise_or_equals("\x04\x05\x06");
is($mv->to_hex, "050707", "bitwise or-equals");
$mv = Crypt::Sodium::XS::MemVault->new("\xad\xbe\xcf")->unlock;
$mv2 = $mv | "\xda\xeb\xfc";
is($mv->to_hex, "adbecf", "overloaded | does not mutate");
is($mv2->to_hex, "ffffff", "overloaded | result");
$mv2 = "\xff\x00\xff" | $mv;
is($mv2->to_hex, "ffbeff", "overloaded | result, reverse args");
$mv |= "\xff\x00\xff";
is($mv->to_hex, "ffbeff", "overloaded |= mutates");

$mv = Crypt::Sodium::XS::MemVault->new("\x01\x02\x03")->unlock;
$mv->bitwise_xor_equals("\x03\x03\x03");
is($mv->to_hex, "020100", "exclusive-or-equals");
$mv->bitwise_xor_equals("\x03\x03\x03");
is($mv->to_hex, "010203", "exclusive-or-equals (roundtrip)");
$mv2 = $mv ^ "\x03\x03\x03";
is($mv->to_hex, "010203", "overloaded ^ does not mutate");
is($mv2->to_hex, "020100", "overloaded ^ result");
$mv2 = "\x03\x03\x03" ^ $mv;
is($mv2->to_hex, "020100", "overloaded ^ result, reverse args");
$mv ^= "\x03\x03\x03";
is($mv->to_hex, "020100", "overloaded ^= mutates");
$mv2 = Crypt::Sodium::XS::MemVault->new("\x03\x03\x03")->unlock;
$mv->bitwise_xor_equals($mv2);
is($mv->to_hex, "010203", "xor_equals method with memvault arg");

my $secret = "secret secrets are no fun...";
my $tmpfile = File::Temp->new;
print $tmpfile $secret;
$tmpfile->flush;
seek($tmpfile, 0, 0);

$mv = Crypt::Sodium::XS::MemVault->new_from_file($tmpfile->filename);
ok($mv->is_locked, "MemVault from file locked by default");
is($mv->length, length($secret), "MemVault from file correct length");
is($mv->unlock, $secret, "MemVault from file correct data");

$mv = Crypt::Sodium::XS::MemVault->new_from_fd(fileno($tmpfile));
is($mv->unlock, $secret, "MemVault from fd correct data");

my $large = scalar "X" x 1025;
seek($tmpfile, 0, 0);
print $tmpfile $large;
$tmpfile->flush;
seek($tmpfile, 0, 0);

$mv = Crypt::Sodium::XS::MemVault->new_from_file($tmpfile->filename);
is($mv->length, 1025, "MemVault (1025) from file correct length");
is($mv->unlock, $large, "MemVault (1025) from file correct data");

$large = scalar "Y" x 2047;

$mv = Crypt::Sodium::XS::MemVault->new($large);
$mv->to_file($tmpfile->filename);
$mv = Crypt::Sodium::XS::MemVault->new_from_file($tmpfile->filename);
is($mv->length, 2047, "MemVault (2047) to file/from file correct length");
is($mv->unlock, $large, "MemVault (2047) roundtripped to file/from file");

$large = scalar "Z" x 8193;

$mv = Crypt::Sodium::XS::MemVault->new($large);
$mv->to_fd(fileno($tmpfile));
$mv = Crypt::Sodium::XS::MemVault->new_from_file($tmpfile->filename);
is($mv->length, 8193, "MemVault (8193) to file/from file correct length");
is($mv->unlock, $large, "MemVault (8193) roundtripped to fd/from file");

{
  local $1;
  PROTMEM_ALL_DISABLED =~ m/([0-9]+)/;
  $mv = Crypt::Sodium::XS::MemVault->new("foobar", $1);
  is($mv->flags, PROTMEM_ALL_DISABLED, "MemVault constructor invokes magic on flags arg");
}

$mv = Crypt::Sodium::XS::MemVault->new("foobar")->unlock;
my $x = $mv->pad(16);
is($mv->pad(16)->to_hex, "666f6f62617280000000000000000000", "sodium_pad foobar blocksize 16");
is($x->unpad(16)->to_hex, "666f6f626172", "sodium_unpad foobar blocksize 16");
$x = $mv->pad(15);
is($x->to_hex, "666f6f626172800000000000000000", "sodium_pad foobar blocksize 15");
is($x->unpad(15)->to_hex, "666f6f626172", "sodium_unpad foobar blocksize 15");
$x = $mv->pad(3);
is($x->to_hex, "666f6f626172800000", "sodium_pad foobar blocksize 3");
is($x->unpad(3)->to_hex, "666f6f626172", "sodium_unpad foobar blocksize 3");
$mv = Crypt::Sodium::XS::MemVault->new("fooba")->unlock;
$x = $mv->pad(3);
is($x->to_hex, "666f6f626180", "sodium_pad fooba blocksize 3");
is($x->unpad(3)->to_hex, "666f6f6261", "sodium_unpad foobar blocksize 3");


done_testing();
