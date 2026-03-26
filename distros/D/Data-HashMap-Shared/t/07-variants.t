use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

# ====== I16 (int16 -> int16 with counters) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16->new($path, 1000);

    # Basic CRUD
    ok(shm_i16_put $map, 0, 0, 'I16: put zero key');
    is(shm_i16_get $map, 0, 0, 'I16: get zero key');
    ok(shm_i16_put $map, -1, -1, 'I16: negative key/value');
    is(shm_i16_get $map, -1, -1, 'I16: get negative');
    ok(shm_i16_put $map, 32767, 32767, 'I16: INT16_MAX');
    is(shm_i16_get $map, 32767, 32767, 'I16: get INT16_MAX');
    ok(shm_i16_put $map, -32768, -32768, 'I16: INT16_MIN key');
    is(shm_i16_get $map, -32768, -32768, 'I16: get INT16_MIN');
    ok(shm_i16_exists $map, 32767, 'I16: exists');
    ok(!shm_i16_exists $map, 100, 'I16: not exists');
    ok(shm_i16_remove $map, 32767, 'I16: remove');
    ok(!defined(shm_i16_get $map, 32767), 'I16: removed');

    # Counters
    is(shm_i16_incr $map, 10, 1, 'I16: incr');
    is(shm_i16_incr $map, 10, 2, 'I16: incr again');
    is(shm_i16_decr $map, 10, 1, 'I16: decr');
    is(shm_i16_incr_by $map, 10, 100, 101, 'I16: incr_by');

    # Iteration
    shm_i16_clear $map;
    shm_i16_put $map, $_, $_ * 2 for 1..5;
    is(shm_i16_size $map, 5, 'I16: size');
    my @k = sort { $a <=> $b } shm_i16_keys $map;
    is_deeply(\@k, [1..5], 'I16: keys');
    my $h = shm_i16_to_hash $map;
    is($h->{3}, 6, 'I16: to_hash');

    # Method API
    $map->put(42, 84);
    is($map->get(42), 84, 'I16: method API');

    unlink $path;
}

# ====== I32 (int32 -> int32 with counters) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32->new($path, 1000);

    ok(shm_i32_put $map, 0, 0, 'I32: zero');
    is(shm_i32_get $map, 0, 0, 'I32: get zero');
    ok(shm_i32_put $map, 2147483647, 2147483647, 'I32: INT32_MAX');
    is(shm_i32_get $map, 2147483647, 2147483647, 'I32: get INT32_MAX');
    ok(shm_i32_put $map, -2147483648, -1, 'I32: INT32_MIN key');
    is(shm_i32_get $map, -2147483648, -1, 'I32: get INT32_MIN key');

    is(shm_i32_incr $map, 100, 1, 'I32: incr');
    is(shm_i32_incr_by $map, 100, 999999, 1000000, 'I32: incr_by large');

    shm_i32_clear $map;
    shm_i32_put $map, $_, $_ for 1..10;
    my @v = sort { $a <=> $b } shm_i32_values $map;
    is_deeply(\@v, [1..10], 'I32: values');

    $map->put(42, 84);
    is($map->get(42), 84, 'I32: method API');

    unlink $path;
}

# ====== I16S (int16 -> string) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16S->new($path, 1000);

    ok(shm_i16s_put $map, 1, "hello", 'I16S: put');
    is(shm_i16s_get $map, 1, "hello", 'I16S: get');

    # UTF-8
    ok(shm_i16s_put $map, 2, "\x{263A}", 'I16S: put UTF-8');
    my $v = shm_i16s_get $map, 2;
    ok(utf8::is_utf8($v), 'I16S: UTF-8 flag preserved');
    is($v, "\x{263A}", 'I16S: UTF-8 value correct');

    # Empty string
    ok(shm_i16s_put $map, 3, "", 'I16S: put empty string');
    is(shm_i16s_get $map, 3, "", 'I16S: get empty string');

    ok(shm_i16s_exists $map, 1, 'I16S: exists');
    ok(shm_i16s_remove $map, 1, 'I16S: remove');
    ok(!defined(shm_i16s_get $map, 1), 'I16S: removed');

    is(shm_i16s_size $map, 2, 'I16S: size');

    # Cursor
    my $cur = shm_i16s_cursor $map;
    my $count = 0;
    while (my ($k, $val) = shm_i16s_cursor_next $cur) { $count++ }
    is($count, 2, 'I16S: cursor');

    $map->put(10, "method");
    is($map->get(10), "method", 'I16S: method API');

    unlink $path;
}

# ====== I32S (int32 -> string) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32S->new($path, 1000);

    ok(shm_i32s_put $map, 100000, "large key", 'I32S: large key');
    is(shm_i32s_get $map, 100000, "large key", 'I32S: get');
    ok(shm_i32s_put $map, -1, "negative", 'I32S: negative key');
    is(shm_i32s_get $map, -1, "negative", 'I32S: get negative');

    shm_i32s_put $map, $_, "v$_" for 1..10;
    my $h = shm_i32s_to_hash $map;
    is($h->{5}, "v5", 'I32S: to_hash');

    $map->put(42, "forty-two");
    is($map->get(42), "forty-two", 'I32S: method API');

    unlink $path;
}

# ====== IS (int64 -> string) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::IS->new($path, 1000);

    ok(shm_is_put $map, 2**40, "big key", 'IS: large int64 key');
    is(shm_is_get $map, 2**40, "big key", 'IS: get large');
    ok(shm_is_put $map, 0, "zero", 'IS: zero key');

    # UTF-8
    ok(shm_is_put $map, 1, "\x{1F600}", 'IS: emoji');
    my $v = shm_is_get $map, 1;
    ok(utf8::is_utf8($v), 'IS: UTF-8 flag');
    is($v, "\x{1F600}", 'IS: emoji correct');

    is(shm_is_size $map, 3, 'IS: size');

    $map->put(99, "method");
    is($map->get(99), "method", 'IS: method API');

    unlink $path;
}

# ====== SI16 (string -> int16 with counters) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI16->new($path, 1000);

    ok(shm_si16_put $map, "a", 1, 'SI16: put');
    is(shm_si16_get $map, "a", 1, 'SI16: get');
    ok(shm_si16_put $map, "max", 32767, 'SI16: INT16_MAX value');
    is(shm_si16_get $map, "max", 32767, 'SI16: get max');
    ok(shm_si16_put $map, "min", -32768, 'SI16: INT16_MIN value');
    is(shm_si16_get $map, "min", -32768, 'SI16: get min');

    # Counters
    is(shm_si16_incr $map, "cnt", 1, 'SI16: incr');
    is(shm_si16_incr $map, "cnt", 2, 'SI16: incr again');
    is(shm_si16_decr $map, "cnt", 1, 'SI16: decr');

    # UTF-8 keys
    ok(shm_si16_put $map, "\x{263A}", 42, 'SI16: UTF-8 key');
    is(shm_si16_get $map, "\x{263A}", 42, 'SI16: get UTF-8 key');

    ok(shm_si16_exists $map, "a", 'SI16: exists');
    ok(shm_si16_remove $map, "a", 'SI16: remove');

    $map->put("method", 10);
    is($map->get("method"), 10, 'SI16: method API');

    unlink $path;
}

# ====== SI32 (string -> int32 with counters) ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI32->new($path, 1000);

    ok(shm_si32_put $map, "key", 1000000, 'SI32: put');
    is(shm_si32_get $map, "key", 1000000, 'SI32: get');
    ok(shm_si32_put $map, "max", 2147483647, 'SI32: INT32_MAX');
    is(shm_si32_get $map, "max", 2147483647, 'SI32: get max');

    is(shm_si32_incr $map, "c", 1, 'SI32: incr');
    is(shm_si32_incr_by $map, "c", 999, 1000, 'SI32: incr_by');

    shm_si32_put $map, "k$_", $_ for 1..10;
    my @k = shm_si32_keys $map;
    ok(scalar @k >= 12, 'SI32: keys count');

    my $h = shm_si32_to_hash $map;
    is($h->{k5}, 5, 'SI32: to_hash');

    $map->put("method", 42);
    is($map->get("method"), 42, 'SI32: method API');

    unlink $path;
}

# ====== each variant with get_or_set ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16->new($path, 1000);
    is(shm_i16_get_or_set $map, 1, 42, 42, 'I16: get_or_set insert');
    is(shm_i16_get_or_set $map, 1, 99, 42, 'I16: get_or_set existing');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32->new($path, 1000);
    is(shm_i32_get_or_set $map, 1, 42, 42, 'I32: get_or_set insert');
    is(shm_i32_get_or_set $map, 1, 99, 42, 'I32: get_or_set existing');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16S->new($path, 1000);
    is(shm_i16s_get_or_set $map, 1, "default", "default", 'I16S: get_or_set');
    is(shm_i16s_get_or_set $map, 1, "other", "default", 'I16S: get_or_set existing');
    unlink $path;
}
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI16->new($path, 1000);
    is(shm_si16_get_or_set $map, "k", 42, 42, 'SI16: get_or_set');
    is(shm_si16_get_or_set $map, "k", 99, 42, 'SI16: get_or_set existing');
    unlink $path;
}

# ====== Stress: many entries across variants ======
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32->new($path, 100000);
    shm_i32_put $map, $_, $_ * 2 for 1..1000;
    is(shm_i32_size $map, 1000, 'I32: 1000 entries');
    is(shm_i32_get $map, 500, 1000, 'I32: get from bulk');
    shm_i32_remove $map, $_ for 1..500;
    is(shm_i32_size $map, 500, 'I32: after bulk remove');
    unlink $path;
}

# ====== add/update/swap/cas on integer variants ======

# I16: add/update/swap/cas
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16->new($path, 1000);
    do { my $_r = shm_i16_add $map, 1, 10; ok($_r, 'I16 add: succeeds on new key') };
    do { my $_r = shm_i16_add $map, 1, 20; ok(!$_r, 'I16 add: fails on existing') };
    do { my $_r = shm_i16_get $map, 1; is($_r, 10, 'I16 add: value unchanged') };
    do { my $_r = shm_i16_update $map, 1, 30; ok($_r, 'I16 update: succeeds on existing') };
    do { my $_r = shm_i16_update $map, 99, 1; ok(!$_r, 'I16 update: fails on missing') };
    do { my $_r = shm_i16_get $map, 1; is($_r, 30, 'I16 update: value changed') };
    my $old = $map->swap(1, 40);
    is($old, 30, 'I16 swap: returns old value');
    my $new_swap = $map->swap(50, 500);
    ok(!defined $new_swap, 'I16 swap: undef for new key');
    do { my $_r = shm_i16_cas $map, 1, 40, 99; ok($_r, 'I16 cas: succeeds') };
    do { my $_r = shm_i16_cas $map, 1, 40, 100; ok(!$_r, 'I16 cas: fails on mismatch') };
    do { my $_r = shm_i16_get $map, 1; is($_r, 99, 'I16 cas: value updated') };
    unlink $path;
}

# I32: add/update/swap/cas
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32->new($path, 1000);
    do { my $_r = shm_i32_add $map, 1, 100; ok($_r, 'I32 add: succeeds') };
    do { my $_r = shm_i32_add $map, 1, 200; ok(!$_r, 'I32 add: fails on existing') };
    do { my $_r = shm_i32_update $map, 1, 300; ok($_r, 'I32 update: succeeds') };
    do { my $_r = shm_i32_get $map, 1; is($_r, 300, 'I32 update: value changed') };
    my $old = $map->swap(1, 400);
    is($old, 300, 'I32 swap: returns old value');
    do { my $_r = shm_i32_cas $map, 1, 400, 999; ok($_r, 'I32 cas: succeeds') };
    do { my $_r = shm_i32_get $map, 1; is($_r, 999, 'I32 cas: value correct') };
    unlink $path;
}

# SI16: add/update/swap/cas (string key → int16 value)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI16->new($path, 1000);
    do { my $_r = shm_si16_add $map, "a", 10; ok($_r, 'SI16 add: succeeds') };
    do { my $_r = shm_si16_add $map, "a", 20; ok(!$_r, 'SI16 add: fails on existing') };
    do { my $_r = shm_si16_update $map, "a", 30; ok($_r, 'SI16 update: succeeds') };
    do { my $_r = shm_si16_get $map, "a"; is($_r, 30, 'SI16 update: value changed') };
    my $old = $map->swap("a", 40);
    is($old, 30, 'SI16 swap: returns old value');
    do { my $_r = shm_si16_cas $map, "a", 40, 99; ok($_r, 'SI16 cas: succeeds') };
    do { my $_r = shm_si16_get $map, "a"; is($_r, 99, 'SI16 cas: value correct') };
    unlink $path;
}

# SI32: add/update/swap/cas
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI32->new($path, 1000);
    do { my $_r = shm_si32_add $map, "key", 100; ok($_r, 'SI32 add: succeeds') };
    do { my $_r = shm_si32_add $map, "key", 200; ok(!$_r, 'SI32 add: fails on existing') };
    do { my $_r = shm_si32_update $map, "key", 300; ok($_r, 'SI32 update: succeeds') };
    my $old = $map->swap("key", 400);
    is($old, 300, 'SI32 swap: returns old value');
    do { my $_r = shm_si32_cas $map, "key", 400, 999; ok($_r, 'SI32 cas: succeeds') };
    do { my $_r = shm_si32_get $map, "key"; is($_r, 999, 'SI32 cas: correct') };
    unlink $path;
}

# ====== add/update/swap on string-value variants (no cas) ======

# IS: add/update/swap (int64 → string)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::IS->new($path, 1000);
    do { my $_r = shm_is_add $map, 1, "hello"; ok($_r, 'IS add: succeeds') };
    do { my $_r = shm_is_add $map, 1, "world"; ok(!$_r, 'IS add: fails on existing') };
    do { my $_r = shm_is_update $map, 1, "updated"; ok($_r, 'IS update: succeeds') };
    my $got = shm_is_get $map, 1;
    is($got, "updated", 'IS update: value changed');
    my $old = $map->swap(1, "swapped");
    is($old, "updated", 'IS swap: returns old value');
    my $new_s = $map->swap(99, "new");
    ok(!defined $new_s, 'IS swap: undef for new key');
    unlink $path;
}

# I16S: add/update/swap
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16S->new($path, 1000);
    do { my $_r = shm_i16s_add $map, 1, "val"; ok($_r, 'I16S add: succeeds') };
    do { my $_r = shm_i16s_add $map, 1, "x"; ok(!$_r, 'I16S add: fails on existing') };
    do { my $_r = shm_i16s_update $map, 1, "new"; ok($_r, 'I16S update: succeeds') };
    my $old = $map->swap(1, "swap");
    is($old, "new", 'I16S swap: returns old');
    unlink $path;
}

# I32S: add/update/swap
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32S->new($path, 1000);
    do { my $_r = shm_i32s_add $map, 1, "val"; ok($_r, 'I32S add: succeeds') };
    do { my $_r = shm_i32s_add $map, 1, "x"; ok(!$_r, 'I32S add: fails on existing') };
    do { my $_r = shm_i32s_update $map, 1, "new"; ok($_r, 'I32S update: succeeds') };
    my $old = $map->swap(1, "swap");
    is($old, "new", 'I32S swap: returns old');
    unlink $path;
}

# ====== persist/set_ttl on non-II variants ======

# I16 with TTL: persist/set_ttl
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I16->new($path, 1000, 0, 30);
    shm_i16_put $map, 1, 10;
    my $rem = shm_i16_ttl_remaining $map, 1;
    ok($rem > 0, 'I16 TTL: entry has TTL');
    do { my $_r = shm_i16_persist $map, 1; ok($_r, 'I16 persist: succeeds') };
    my $rem2 = shm_i16_ttl_remaining $map, 1;
    is($rem2, 0, 'I16 persist: now permanent');
    shm_i16_put $map, 2, 20;
    ok($map->set_ttl(2, 120), 'I16 set_ttl: succeeds');
    my $rem3 = shm_i16_ttl_remaining $map, 2;
    ok($rem3 > 30 && $rem3 <= 120, 'I16 set_ttl: TTL changed');
    unlink $path;
}

# SI16 with TTL: persist/set_ttl
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI16->new($path, 1000, 0, 30);
    shm_si16_put $map, "key", 10;
    do { my $_r = shm_si16_persist $map, "key"; ok($_r, 'SI16 persist: succeeds') };
    my $rem = shm_si16_ttl_remaining $map, "key";
    is($rem, 0, 'SI16 persist: permanent');
    shm_si16_put $map, "k2", 20;
    ok($map->set_ttl("k2", 90), 'SI16 set_ttl: succeeds');
    unlink $path;
}

# IS with TTL: persist/set_ttl
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::IS->new($path, 1000, 0, 30);
    shm_is_put $map, 1, "hello";
    do { my $_r = shm_is_persist $map, 1; ok($_r, 'IS persist: succeeds') };
    my $rem = shm_is_ttl_remaining $map, 1;
    is($rem, 0, 'IS persist: permanent');
    shm_is_put $map, 2, "world";
    ok($map->set_ttl(2, 90), 'IS set_ttl: succeeds');
    unlink $path;
}

# I32S with TTL: persist/set_ttl
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::I32S->new($path, 1000, 0, 30);
    shm_i32s_put $map, 1, "val";
    do { my $_r = shm_i32s_persist $map, 1; ok($_r, 'I32S persist: succeeds') };
    my $rem = shm_i32s_ttl_remaining $map, 1;
    is($rem, 0, 'I32S persist: permanent');
    unlink $path;
}

# SI32 with TTL: persist/set_ttl
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI32->new($path, 1000, 0, 30);
    shm_si32_put $map, "k", 10;
    do { my $_r = shm_si32_persist $map, "k"; ok($_r, 'SI32 persist: succeeds') };
    my $rem = shm_si32_ttl_remaining $map, "k";
    is($rem, 0, 'SI32 persist: permanent');
    ok($map->set_ttl("k", 60), 'SI32 set_ttl: wait, key is permanent');
    # set_ttl on permanent key — changes it back to TTL
    my $rem2 = shm_si32_ttl_remaining $map, "k";
    ok($rem2 > 0, 'SI32 set_ttl: permanent→TTL works');
    unlink $path;
}

done_testing;
