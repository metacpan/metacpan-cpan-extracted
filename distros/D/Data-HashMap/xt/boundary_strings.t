use strict;
use warnings;
use Test::More;

use Data::HashMap::SS;
use Data::HashMap::IS;
use Data::HashMap::SI;

# ---- Empty strings ----

{
    my $m = Data::HashMap::SS->new();
    $m->put("", "empty-key-value");
    is $m->get(""), "empty-key-value", 'SS: empty-string key works';
    $m->put("nonempty", "");
    is $m->get("nonempty"), "", 'SS: empty-string value works';
    is $m->size, 2, 'SS: both empty-string cases coexist';
}

# ---- Embedded NULs ----

{
    my $m = Data::HashMap::SS->new();
    my $k = "a\0b\0c";
    my $v = "x\0y\0z";
    $m->put($k, $v);
    is $m->get($k), $v, 'SS: key and value with embedded NULs';
    # Ensure probe-by-bytes doesn't truncate at NUL
    $m->put("a", "short");
    is $m->get("a"), "short", 'SS: short key distinct from NUL-containing key';
    is $m->get($k), $v, 'SS: NUL-containing key still distinct';
    is $m->size, 2, 'SS: both keys coexist';
}

# ---- Mixed UTF-8 / bytes ----
# Post-Pass-1 fix: identity is byte-based only; the UTF-8 flag is metadata
# for retrieval, not key identity. "\x{2603}" (utf8 flag on) and its
# encoded bytes "\xE2\x98\x83" (flag off) share the same internal 3 bytes,
# so they COLLIDE as the same key.

{
    my $m = Data::HashMap::SS->new();
    my $utf8 = "\x{2603}";
    my $bytes = "\xE2\x98\x83";
    $m->put($utf8, "u");
    is $m->get($utf8), "u", 'UTF-8 flag-on key retrievable';
    $m->put($bytes, "b");
    is $m->size, 1, 'UTF-8 vs encoded-bytes collide (bytes-only identity)';
    is $m->get($utf8), "b", 'second put via encoded-bytes updated value';
}

# ---- Moderately large strings (1MB) ----

{
    my $m = Data::HashMap::SS->new();
    my $large = 'z' x (1024 * 1024);
    ok $m->put("big", $large), 'SS: 1MB value stored';
    is length($m->get("big")), length($large), 'SS: 1MB value length preserved';
    is $m->get("big"), $large, 'SS: 1MB value byte-identical';
}

# ---- Binary-safe IS values ----

{
    my $m = Data::HashMap::IS->new();
    my $bin = join('', map chr, 0..255);
    $m->put(1, $bin);
    is $m->get(1), $bin, 'IS: binary value (all 256 byte values) preserved';
}

# ---- SI with long string keys ----

{
    my $m = Data::HashMap::SI->new();
    my $long = "k" x 10_000;
    $m->put($long, 42);
    is $m->get($long), 42, 'SI: 10KB key';
    # Toggle one byte — distinct key
    my $long2 = "k" x 9_999 . "x";
    $m->put($long2, 43);
    is $m->size, 2, 'SI: one-byte-different long keys distinct';
    is $m->get($long), 42, 'SI: original long key still 42';
    is $m->get($long2), 43, 'SI: tweaked long key is 43';
}

done_testing;
