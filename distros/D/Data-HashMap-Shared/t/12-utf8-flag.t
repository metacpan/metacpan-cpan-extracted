use strict;
use warnings;
use utf8;
use Test::More;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::IS;

# Regression: hashing is byte-based; the SV utf8 flag is metadata for
# restoring the returned SV's flag on retrieval, not part of key identity.
# Same bytes with toggled flag must hit the same entry.

# SS variant — ASCII keys, flag toggling
{
    my $m = Data::HashMap::Shared::SS->new(undef, 16);
    my $k = "hello";
    $m->put($k, "world");

    my $k_up = "hello"; utf8::upgrade($k_up);
    my $k_dn = "hello"; utf8::downgrade($k_dn);
    is $m->get($k_up), "world", 'SS: utf8=on hits entry stored with utf8=off';
    is $m->get($k_dn), "world", 'SS: utf8=off hits entry stored with utf8=off';
    ok $m->exists($k_up), 'SS: exists ignores flag';
    ok $m->exists($k_dn), 'SS: exists ignores flag (dn)';
}

# SI variant — ASCII key
{
    my $m = Data::HashMap::Shared::SI->new(undef, 16);
    my $k = "answer";
    $m->put($k, 42);

    my $k_up = "answer"; utf8::upgrade($k_up);
    is $m->get($k_up), 42, 'SI: utf8 flag ignored on lookup';
}

# IS variant — integer key, string value. Value UTF-8 flag must round-trip.
{
    my $m = Data::HashMap::Shared::IS->new(undef, 16);
    my $utf8_val = "café"; utf8::upgrade($utf8_val);
    $m->put(1, $utf8_val);
    my $got = $m->get(1);
    is $got, $utf8_val, 'IS: value bytes round-trip';
    ok utf8::is_utf8($got), 'IS: stored utf8 flag restored on retrieval';

    # Plain (non-utf8) value also round-trips with flag off.
    $m->put(2, "plain");
    my $plain = $m->get(2);
    is $plain, "plain";
    ok !utf8::is_utf8($plain), 'IS: plain value retains flag-off';
}

# Non-ASCII byte-distinct keys remain distinct (expected byte-level behavior)
{
    my $m = Data::HashMap::Shared::SS->new(undef, 16);
    my $u = "café";  utf8::upgrade($u);    # bytes: c3 a9
    my $d = "caf\xe9"; utf8::downgrade($d); # bytes: e9
    $m->put($u, "utf8-bytes");
    $m->put($d, "latin1-bytes");
    isnt $m->get($u), $m->get($d),
        'SS: distinct byte encodings remain distinct keys (byte-level semantics)';
    is $m->get($u), "utf8-bytes";
    is $m->get($d), "latin1-bytes";
}

# put after initial put with toggled flag: should UPDATE the existing entry
{
    my $m = Data::HashMap::Shared::SS->new(undef, 16);
    my $k1 = "counter"; # flag off
    $m->put($k1, "first");
    is $m->size, 1, 'one entry after first put';

    my $k2 = "counter"; utf8::upgrade($k2);
    $m->put($k2, "second");
    is $m->size, 1, 'second put with toggled flag updates (does not insert duplicate)';
    is $m->get($k1), "second", 'value is the most recent put';
}

# add/update/swap/cas/remove/take with toggled flag all hit the same entry
{
    my $m = Data::HashMap::Shared::SI->new(undef, 16);
    my $k = "slot"; $m->put($k, 1);

    my $up = "slot"; utf8::upgrade($up);
    ok $m->update($up, 2), 'update with flag-toggled key';
    is $m->get($k), 2;

    is $m->swap($up, 3), 2, 'swap returns prior via toggled key';
    is $m->get($k), 3;

    ok $m->cas($up, 3, 4), 'cas with toggled key';
    is $m->get($k), 4;

    ok !$m->add($up, 99), 'add on existing key (toggled flag) is rejected';

    is $m->take($up), 4, 'take with toggled flag removes and returns value';
    ok !$m->exists($k), 'entry removed after take';
}

# put_ttl with toggled flag
{
    my $m = Data::HashMap::Shared::SI->new(undef, 16, 0, 1);  # default ttl=1s
    my $k = "exp"; $m->put_ttl($k, 42, 60);

    my $up = "exp"; utf8::upgrade($up);
    is $m->get($up), 42, 'put_ttl entry retrievable via toggled-flag key';
    ok $m->set_ttl($up, 120), 'set_ttl via toggled-flag key';
}

# Cursor / keys() must return the stored flag on ASCII keys
{
    my $m = Data::HashMap::Shared::SS->new(undef, 16);
    my $flagged = "key"; utf8::upgrade($flagged);
    $m->put($flagged, "val");
    my @ks = $m->keys;
    is scalar(@ks), 1;
    is $ks[0], "key";
    ok utf8::is_utf8($ks[0]), 'retrieved key carries original utf8 flag';

    # Lookup via flag-off version still works.
    my $plain = "key"; utf8::downgrade($plain);
    is $m->get($plain), "val", 'lookup via downgraded ASCII matches';
}

# Sharded variant: UTF-8 fix propagates through shard dispatch
{
    use File::Temp qw(tempdir);
    my $dir = tempdir(CLEANUP => 1);
    my $prefix = "$dir/sharded";
    my $m = Data::HashMap::Shared::SS->new_sharded($prefix, 4, 16);
    my $k = "anchor"; $m->put($k, "value");
    my $up = "anchor"; utf8::upgrade($up);
    is $m->get($up), "value", 'sharded: toggled-flag lookup hits';
}

done_testing;
