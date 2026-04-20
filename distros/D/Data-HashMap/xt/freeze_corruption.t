use strict;
use warnings;
use Test::More;

use Data::HashMap::II;
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

done_testing;
