use strict;
use warnings;
use Test::More;
use MIME::Base64 'encode_base64';
use File::Temp;

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

  eval { $mv lt $mv_clone ? 1 : 0 };
  like($@, qr/Operation "lt" on MemVault is not supported/,
       'Operation "lt" is not supported');
  eval { $mv le $mv_clone ? 1 : 0 };
  like($@, qr/Operation "le" on MemVault is not supported/,
       'Operation "le" is not supported');

  eval { $mv gt $mv_clone ? 1 : 0 };
  like($@, qr/Operation "gt" on MemVault is not supported/,
       'Operation "gt" is not supported');
  eval { $mv ge $mv_clone ? 1 : 0 };
  like($@, qr/Operation "ge" on MemVault is not supported/,
       'Operation "ge" is not supported');

  ok($mv eq $mv_data, "mv eq mv_data");
  ok($mv_data eq $mv, "mv_data eq mv");
  ok($mv eq $mv_clone, "mv eq clone");
  ok(!($mv ne $mv_clone), "! mv ne clone");
  ok($mv, "boolean mv");

  $mv->unlock;

  my $mv_str = "$mv";
  is($mv_str, $mv, "stringification works");
  is(ref $mv_str, '', "stringified object is not a ref");
  is($mv_str, $mv_data, "stringified object correct bytes");

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
  ok($mv_aaa->is_locked, "concat MV . SV locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "concat MV . SV, correct result");

  $mv_clone .= "aaa";
  ok($mv_clone->is_locked, "MV .= SV locked, result locked");
  is($mv_clone->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     ".= correct results");

  my $aaa_key = "aaa" . $mv;
  isa_ok($aaa_key, "Crypt::Sodium::XS::MemVault");
  ok($aaa_key->is_locked, "concat SV . MV locked, result locked");
  is($aaa_key->to_hex->unlock, unpack("H*", "aaa" . $mv_data),
     "concat SV . MV, correct result");

  $mv_aaa = $mv . Crypt::Sodium::XS::MemVault->new("aaa");
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok($mv_aaa->is_locked, "concat MV . MV both locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "concat MV . MV both locked, correct result");

  $mv_aaa = $mv . Crypt::Sodium::XS::MemVault->new("aaa");
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok($mv_aaa->is_locked, "concat MV . MV one locked, result locked");
  is($mv_aaa->to_hex->unlock, unpack("H*", $mv_data . "aaa"),
     "concat MV . MV one locked, correct result");

  $mv_aaa = $mv->clone->unlock . Crypt::Sodium::XS::MemVault->new("aaa")->unlock;
  isa_ok($mv_aaa, "Crypt::Sodium::XS::MemVault");
  ok(!$mv_aaa->is_locked, "concat MV . MV none locked, result unlocked");
  is($mv_aaa->to_hex, unpack("H*", $mv_data . "aaa"),
     "concat MV . MV none locked, correct result");

  my $mv_x_5 = $mv x 5;
  isa_ok($mv_x_5, "Crypt::Sodium::XS::MemVault");
  ok($mv_x_5->is_locked, "repitition of locked MemVault is locked");

  is($mv_x_5->unlock,
    "${mv_data}${mv_data}${mv_data}${mv_data}${mv_data}", "mv x 5");
}

{ # compare
  my $x = Crypt::Sodium::XS::MemVault->new("abc");
  my $y = "abC";
  my $z = Crypt::Sodium::XS::MemVault->new("abC");

  ok($x->memcmp("abc"), "memcmp: MV to same SV are equal");
  ok(!$x->compare("abc"), "compare: MV to same SV are equal");
  ok(!$x->memcmp($y), "memcmp: 'MV to differnet SV differ");
  ok($x->compare($y), "compare: 'MV to differnet SV differ");
  ok(!$x->memcmp($z), "memcmp: MV to different MV differ");
  ok($x->compare($z), "compare: MV to different MV differ");
  ok($x->memcmp("abcdefghi", 2), "memcmp: MV to SV with length are equal");
  ok(!$x->compare("abcdefghi", 2), "compare: MV to SV with length are equal");
  ok(!$x->memcmp("zbc", 2), "memcmp: MV to different SV with length differ");
  ok($x->compare("zbc", 2), "compare: MV to different SV with length differ");
  $y = Crypt::Sodium::XS::MemVault->new("abcdefghi");
  $z = Crypt::Sodium::XS::MemVault->new("zbcdef");
  ok($x->memcmp($y, 2), "memcmp: MV to MV with length are equal");
  ok(!$x->compare($y, 2), "compare: MV to MV with length are equal");
  ok(!$x->memcmp($z, 2), "memcmp: MV to different MV with length differ");
  ok($x->compare($z, 2), "compare: MV to different MV with length differ");

  eval { my $res = $x->memcmp("abcde"); };
  like($@, qr/Variables of unequal length/,
       "memcmp of unequal length must specify length");
  eval { my $res = $x->compare("ab"); };
  like($@, qr/Variables of unequal length/,
       "compare of unequal length must specify length");
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
    my $mv1 = Crypt::Sodium::XS::MemVault->new($buf1);
    my $mv2 = Crypt::Sodium::XS::MemVault->new($buf2);
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

my $mv = Crypt::Sodium::XS::MemVault->new("\x01\x02\x03");
$mv->xor("\x03\x03\x03");
is($mv->to_hex->unlock, "020100", "exclusive or");
$mv->xor("\x03\x03\x03");
is($mv->to_hex->unlock, "010203", "exclusive or (roundtrip)");
my $mv2 = $mv ^ "\x03\x03\x03";
is($mv->to_hex->unlock, "010203", "overloaded ^ does not mutate");
is($mv2->to_hex->unlock, "020100", "overloaded ^ result");
$mv2 = "\x03\x03\x03" ^ $mv;
is($mv2->to_hex->unlock, "020100", "overloaded ^ result, reverse args");
$mv ^= "\x03\x03\x03";
is($mv->to_hex->unlock, "020100", "overloaded ^= mutates");
$mv2 = Crypt::Sodium::XS::MemVault->new("\x03\x03\x03");
$mv->xor($mv2);
is($mv->to_hex->unlock, "010203", "xor method with memvault arg");

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

done_testing();
