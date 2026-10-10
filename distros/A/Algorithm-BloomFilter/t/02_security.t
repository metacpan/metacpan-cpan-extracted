use strict;
use warnings;
use Test::More;
use Algorithm::BloomFilter;

# 1. Deserialization with truncated, empty, or corrupted blobs
# (must return undef, not crash with SIGSEGV or wrap NULL pointer in blessed object).
{
  # Empty blob
  my $bf = Algorithm::BloomFilter->deserialize("");
  is($bf, undef, "deserializing empty blob returns undef");

  # 1-byte blob
  $bf = Algorithm::BloomFilter->deserialize("X");
  is($bf, undef, "deserializing 1-byte blob returns undef");

  # 1-byte blob with varint high bit set
  $bf = Algorithm::BloomFilter->deserialize("\x80");
  is($bf, undef, "deserializing 1-byte blob with high bit returns undef");

  # Varint overflow / malformed varint (11 bytes with 0x80 set)
  $bf = Algorithm::BloomFilter->deserialize("\x80" x 12);
  is($bf, undef, "deserializing malformed varint sequence returns undef");

  # Truncated after k
  $bf = Algorithm::BloomFilter->deserialize("\x03");
  is($bf, undef, "deserializing blob truncated after k returns undef");

  # Corrupted data with k=0
  # k=0, significant_bits=3, 1 byte payload
  $bf = Algorithm::BloomFilter->deserialize("\x00\x03\x00");
  is($bf, undef, "deserializing blob with k=0 returns undef");

  # Invalid significant_bits: power < 3
  $bf = Algorithm::BloomFilter->deserialize("\x03\x02\x00");
  is($bf, undef, "deserializing blob with significant_bits < 3 returns undef");

  # Invalid significant_bits: power >= 64
  $bf = Algorithm::BloomFilter->deserialize("\x03\x40\x00");
  is($bf, undef, "deserializing blob with significant_bits >= 64 returns undef");
}

# 2. Deserialization with mismatched significant_bits vs bitmap length
# (e.g. high significant_bits but truncated payload must fail safely and return undef).
{
  # significant_bits = 10 -> expected_bytes = 1024 / 8 = 128 bytes.
  # But payload provided is only 4 bytes.
  # k=3 (\x03), significant_bits=10 (\x0a), payload="1234"
  my $blob = "\x03\x0a" . ("\x00" x 4);
  my $bf = Algorithm::BloomFilter->deserialize($blob);
  is($bf, undef, "deserializing payload shorter than expected returns undef");

  # Payload longer than expected:
  # significant_bits = 3 -> expected_bytes = 8 / 8 = 1 byte.
  # But payload provided is 2 bytes.
  $blob = "\x03\x03\x00\x00";
  $bf = Algorithm::BloomFilter->deserialize($blob);
  is($bf, undef, "deserializing payload longer than expected returns undef");

  # Large significant_bits (e.g. 30 -> 128MB or 40), truncated payload
  $blob = "\x03\x28" . ("\x00" x 10);
  $bf = Algorithm::BloomFilter->deserialize($blob);
  is($bf, undef, "deserializing large significant_bits with truncated payload returns undef");
}

# 3. Deserialization with empty blob "" or 1-byte blob (no pointer underflow or integer wrap)
{
  is(Algorithm::BloomFilter->deserialize(""), undef, "empty string safely rejected");
  is(Algorithm::BloomFilter->deserialize("\x00"), undef, "single zero byte safely rejected");
  is(Algorithm::BloomFilter->deserialize("\xff"), undef, "single 0xff byte safely rejected");
}

# 4. bl_alloc / new() with extreme values (e.g. -1, ~0, 0, 1, 2)
# to ensure no infinite loop or zero-byte buffer allocation.
{
  # k_hashes = 0 should fail
  eval { Algorithm::BloomFilter->new(16, 0); };
  ok($@, "new() with k_hashes = 0 croaks / fails");

  # n_bits = 0 should fail
  eval { Algorithm::BloomFilter->new(0, 1); };
  ok($@, "new() with n_bits = 0 croaks / fails");

  # n_bits = 1, 2 -> power would be 1 or 2 (< 3), should fail
  eval { Algorithm::BloomFilter->new(1, 1); };
  ok($@, "new() with n_bits = 1 croaks / fails");

  eval { Algorithm::BloomFilter->new(2, 1); };
  ok($@, "new() with n_bits = 2 (power 2 < 3) croaks / fails");

  # n_bits = 3, 4 -> power 3 (2^3 = 8), succeeds!
  my $bf3 = eval { Algorithm::BloomFilter->new(3, 1); };
  ok(!$@ && defined $bf3, "new() with n_bits = 3 (power 3) succeeds");

  my $bf4 = eval { Algorithm::BloomFilter->new(4, 1); };
  ok(!$@ && defined $bf4, "new() with n_bits = 4 (power 3) succeeds");

  # n_bits = 5 -> next power of two is 8 (power = 4, 16 bits = 2 bytes)
  my $bf = eval { Algorithm::BloomFilter->new(5, 1); };
  ok(!$@ && defined $bf, "new() with n_bits = 5 (power 4) succeeds");
  isa_ok($bf, "Algorithm::BloomFilter");

  # Extreme values: -1, ~0
  eval { Algorithm::BloomFilter->new(-1, 1); };
  ok($@, "new() with n_bits = -1 croaks / fails");

  eval { Algorithm::BloomFilter->new(~0, 1); };
  ok($@, "new() with n_bits = ~0 croaks / fails");

  eval { Algorithm::BloomFilter->new(100, -1); };
  # -1 as UV is huge, might fail memory allocation or croak
  # We test that it doesn't hang or segfault
  # Note: if k_hashes is huge, alloc might succeed or fail, but must not crash
  my $eval_err = $@;
  pass("new() with k_hashes = -1 handled safely");
}

# 5. serialize / deserialize roundtrip
# (ensure clean roundtrip, correct length, no uninitialized trailing byte).
{
  # Minimum valid size: n_bits = 4 -> power = 3, nbytes = 1 byte
  # k=2 (1 byte varint: 0x02), significant_bits=3 (1 byte varint: 0x03), bitmap=1 byte => total 3 bytes
  my $bf = Algorithm::BloomFilter->new(4, 2);
  isa_ok($bf, "Algorithm::BloomFilter");
  $bf->add("test");
  is($bf->test("test"), 1, "test in filter");
  is($bf->test("not_in"), 0, "not_in not in filter");

  my $blob = $bf->serialize();
  is(length($blob), 3, "serialized length is exact (no uninitialized trailing byte)");

  my $bf2 = Algorithm::BloomFilter->deserialize($blob);
  isa_ok($bf2, "Algorithm::BloomFilter");
  is($bf2->test("test"), 1, "roundtrip preserves added item");
  is($bf2->test("not_in"), 0, "roundtrip preserves non-added item");

  # Reserializing bf2 should match $blob exactly
  my $blob2 = $bf2->serialize();
  is($blob2, $blob, "reserialized blob matches original blob exactly");

  # Also test with larger filter: n_bits = 1000 -> power = 11 (2^11 = 2048 bits = 256 bytes)
  # k = 5.
  # Serialized size: k (1 byte) + significant_bits (1 byte) + 256 bytes = 258 bytes.
  my $bf_large = Algorithm::BloomFilter->new(1000, 5);
  $bf_large->add("hello", "world");
  my $large_blob = $bf_large->serialize();
  is(length($large_blob), 258, "large filter serialized length is exact (258 bytes)");

  my $bf_large_res = Algorithm::BloomFilter->deserialize($large_blob);
  isa_ok($bf_large_res, "Algorithm::BloomFilter");
  is($bf_large_res->test("hello"), 1, "large filter roundtrip item 1");
  is($bf_large_res->test("world"), 1, "large filter roundtrip item 2");
  is($bf_large_res->test("foo"), 0, "large filter roundtrip negative test");
}

# 6. Type check: calling methods with invalid objects of other classes must fail/croak.
{
  my $foreign_obj = bless {}, "Some::Other::Class";
  my $scalar = "not an object";

  eval { Algorithm::BloomFilter::add($foreign_obj, "foo"); };
  like($@, qr/is not a blessed SV reference/, "calling add() with foreign object croaks");

  eval { Algorithm::BloomFilter::test($foreign_obj, "foo"); };
  like($@, qr/is not a blessed SV reference/, "calling test() with foreign object croaks");

  eval { Algorithm::BloomFilter::serialize($foreign_obj); };
  like($@, qr/is not a blessed SV reference/, "calling serialize() with foreign object croaks");

  eval { Algorithm::BloomFilter::merge($foreign_obj, $foreign_obj); };
  like($@, qr/is not a blessed SV reference/, "calling merge() with foreign object croaks");

  eval { Algorithm::BloomFilter::DESTROY($foreign_obj); };
  like($@, qr/is not a blessed SV reference/, "calling DESTROY() with foreign object croaks");

  # Also test with unblessed scalar
  eval { Algorithm::BloomFilter::test($scalar, "foo"); };
  like($@, qr/is not a blessed SV reference/, "calling test() with scalar croaks");

  # Test merge with valid self but invalid other
  my $valid_bf = Algorithm::BloomFilter->new(100, 2);
  eval { $valid_bf->merge($foreign_obj); };
  like($@, qr/is not a blessed SV reference/, "calling merge() with valid self and foreign other croaks");
}

done_testing();
