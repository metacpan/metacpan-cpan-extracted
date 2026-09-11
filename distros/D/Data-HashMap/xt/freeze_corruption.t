use strict;
use warnings;
use Test::More;

use Data::HashMap::I16;
use Data::HashMap::I16S;
use Data::HashMap::I32;
use Data::HashMap::I32S;
use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::SI;
use Data::HashMap::SI16;
use Data::HashMap::SI32;
use Data::HashMap::SS;

# Build a known-good freeze, then mangle it in various ways.

my $good = do {
    my $m = Data::HashMap::II->new();
    $m->put(1, 100);
    $m->put(2, 200);
    $m->freeze;
};

# ---- Truncation ----

for my $trunc (1, 4, 10, length($good) - 1) {
    my $bad = substr($good, 0, $trunc);
    my $m = eval { Data::HashMap::II->thaw($bad) };
    ok !defined($m), "truncated to $trunc bytes: thaw rejected";
}

# ---- Bad magic ----

{
    my $bad = $good;
    substr($bad, 0, 4) = "XXXX";
    my $m = eval { Data::HashMap::II->thaw($bad) };
    ok !defined($m), 'bad magic: thaw rejected';
}

# ---- Wrong version ----

{
    my $bad = $good;
    substr($bad, 4, 1) = chr(99);
    my $m = eval { Data::HashMap::II->thaw($bad) };
    ok !defined($m), 'wrong version: thaw rejected';
}

# ---- Wrong variant id ----

{
    my $bad = $good;
    substr($bad, 5, 1) = chr(42);
    my $m = eval { Data::HashMap::II->thaw($bad) };
    ok !defined($m), 'wrong variant id: thaw rejected';
}

# ---- Claimed count > actual entries ----

{
    my $bad = $good;
    substr($bad, 6, 4) = pack('V', 100);  # claim 100 entries when body has 2
    my $m = eval { Data::HashMap::II->thaw($bad) };
    ok !defined($m), 'count mismatch (too high): thaw rejected';
}

# ---- SS with embedded UTF-8 values ----

{
    my $m = Data::HashMap::SS->new();
    my $v = "\x{2603}";
    utf8::encode(my $enc = $v);
    $m->put("snow", $v);
    my $s = $m->freeze;
    my $m2 = Data::HashMap::SS->thaw($s);
    is $m2->get("snow"), $v, 'SS: UTF-8 value round-trips';
    ok utf8::is_utf8($m2->get("snow")), 'SS: UTF-8 flag preserved';
}

# ---- Empty map ----

{
    my $m = Data::HashMap::II->new();
    my $s = $m->freeze;
    my $m2 = Data::HashMap::II->thaw($s);
    is $m2->size, 0, 'empty map round-trips';
}

# ---- Oversized string length fields ----
# The is() on each offset fails loudly if the freeze layout moves.

my @len_fields = (
    ['Data::HashMap::SS',   sub { $_[0]->put("ab", "cd") }, 22,           'SS key len'],
    ['Data::HashMap::SS',   sub { $_[0]->put("ab", "cd") }, 22 + 4+1+2,   'SS value len'],
    ['Data::HashMap::SI',   sub { $_[0]->put("ab", 7) },    22,           'SI key len'],
    ['Data::HashMap::SI32', sub { $_[0]->put("ab", 7) },    22,           'SI32 key len'],
    ['Data::HashMap::SI16', sub { $_[0]->put("ab", 7) },    22,           'SI16 key len'],
    ['Data::HashMap::IS',   sub { $_[0]->put(1, "cd") },    22 + 8,       'IS value len'],
    ['Data::HashMap::I32S', sub { $_[0]->put(1, "cd") },    22 + 4,       'I32S value len'],
    ['Data::HashMap::I16S', sub { $_[0]->put(1, "cd") },    22 + 2,       'I16S value len'],
);

for my $case (@len_fields) {
    my ($class, $populate, $off, $label) = @$case;
    my $m = $class->new();
    $populate->($m);
    my $blob = $m->freeze;

    is unpack('L', substr($blob, $off, 4)), 2, "$label: field is at offset $off";

    for my $len (0xFFFFFFFF, 0x80000000, 0x7FFFFFFF, 1000) {
        my $bad = $blob;
        substr($bad, $off, 4) = pack('L', $len);
        my $got = eval { $class->thaw($bad) };
        ok !defined($got), sprintf('%s = 0x%X: thaw rejected', $label, $len);
        like $@, qr/Truncated freeze data/, sprintf('%s = 0x%X: bounds message', $label, $len);
    }
}

# ---- Inflated entry count, every thaw-capable variant ----

my @counted = (
    ['Data::HashMap::I16',  sub { $_[0]->put(1, 2) }],
    ['Data::HashMap::I16S', sub { $_[0]->put(1, "x") }],
    ['Data::HashMap::I32',  sub { $_[0]->put(1, 2) }],
    ['Data::HashMap::I32S', sub { $_[0]->put(1, "x") }],
    ['Data::HashMap::II',   sub { $_[0]->put(1, 2) }],
    ['Data::HashMap::IS',   sub { $_[0]->put(1, "x") }],
    ['Data::HashMap::SI',   sub { $_[0]->put("a", 2) }],
    ['Data::HashMap::SI16', sub { $_[0]->put("a", 2) }],
    ['Data::HashMap::SI32', sub { $_[0]->put("a", 2) }],
    ['Data::HashMap::SS',   sub { $_[0]->put("a", "x") }],
);

for my $case (@counted) {
    my ($class, $populate) = @$case;
    my $m = $class->new();
    $populate->($m);
    my $bad = $m->freeze;
    substr($bad, 6, 4) = pack('L', 100_000_000);
    my $got = eval { $class->thaw($bad) };
    ok !defined($got), "$class: inflated count rejected";
    like $@, qr/Truncated freeze data/, "$class: inflated count croaks before allocating";
}

done_testing;
