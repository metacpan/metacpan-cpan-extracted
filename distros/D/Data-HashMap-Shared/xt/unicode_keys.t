use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode_utf8);

use Data::HashMap::Shared::SS;

my $m = Data::HashMap::Shared::SS->new(undef, 1024);

# NUL byte inside key (binary-opaque)
my $k1 = "abc\x00def";
$m->put($k1, "v1");
is $m->get($k1), "v1", 'NUL-byte key roundtrip';
ok !defined($m->get("abc")), 'prefix does not match NUL-truncated';

# Zero-length key
$m->put("", "empty");
is $m->get(""), "empty", 'zero-length key';

# Combining diacritics (NFD form)
my $nfd = "e\x{0301}";  # e + combining acute
my $nfc = "é";          # composed
$m->put(encode_utf8($nfd), "dec");
$m->put(encode_utf8($nfc), "com");
is $m->get(encode_utf8($nfd)), "dec", 'NFD key distinct from NFC';
is $m->get(encode_utf8($nfc)), "com", 'NFC key distinct from NFD';

# All bytes 0..255 as a key
my $binkey = join '', map chr, 0..255;
$m->put($binkey, "allbytes");
is $m->get($binkey), "allbytes", 'full-byte-range key';

# Long UTF-8
my $long = encode_utf8("\x{1F600}" x 100);
$m->put($long, "emoji");
is $m->get($long), "emoji", 'long UTF-8 key';

done_testing;
