use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_newops') . '.shm' }

# update_ttl: int-value variant
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100, 0, 30);
    ok(!$map->update_ttl(1, 99, 60), 'II update_ttl: fails on missing key');
    $map->put(1, 100);
    ok($map->update_ttl(1, 200, 90), 'II update_ttl: succeeds on existing');
    is($map->get(1), 200, 'II update_ttl: value changed');
    my $rem = shm_ii_ttl_remaining $map, 1;
    ok($rem > 30 && $rem <= 90, "II update_ttl: TTL applied (rem=$rem)");
    # ttl=0 → permanent
    ok($map->update_ttl(1, 300, 0), 'II update_ttl: succeeds with ttl=0');
    is(scalar(shm_ii_ttl_remaining $map, 1), 0, 'II update_ttl: ttl=0 → permanent');
    unlink $path;
}

# update_ttl: string-value variant
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 100, 0, 30);
    ok(!$map->update_ttl("k", "v", 60), 'SS update_ttl: fails on missing');
    $map->put("k", "v0");
    ok($map->update_ttl("k", "v1", 90), 'SS update_ttl: succeeds');
    is($map->get("k"), "v1", 'SS update_ttl: value changed');
    my $rem = shm_ss_ttl_remaining $map, "k";
    ok($rem > 30 && $rem <= 90, "SS update_ttl: TTL applied (rem=$rem)");
    unlink $path;
}

# update_ttl: croak on non-TTL map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    eval { $map->update_ttl(1, 1, 60) };
    like($@, qr/TTL-enabled/, 'update_ttl croaks on non-TTL map');
    unlink $path;
}

# cas_take: int-value
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    $map->put(1, 100);
    is($map->cas_take(1, 99), undef, 'II cas_take: mismatch returns undef');
    is($map->get(1), 100, 'II cas_take: mismatch leaves value');
    is($map->cas_take(1, 100), 100, 'II cas_take: match returns removed value');
    ok(!$map->exists(1), 'II cas_take: key removed on match');
    is($map->cas_take(999, 0), undef, 'II cas_take: missing key returns undef');
    unlink $path;
}

# cas_take: string-value (byte-only compare; UTF-8 flag ignored on expected)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 100);
    $map->put("k", "v1");
    is($map->cas_take("k", "wrong"), undef, 'SS cas_take: mismatch returns undef');
    is($map->cas_take("k", "v1"), "v1", 'SS cas_take: match returns value');
    ok(!$map->exists("k"), 'SS cas_take: key removed');
    # UTF-8 toggle
    $map->put("u", "abc");
    my $up = "abc"; utf8::upgrade($up);
    is($map->cas_take("u", $up), "abc", 'SS cas_take: utf8-upgraded expected matches ASCII');
    unlink $path;
}

# cas_take: keyword form for int-value
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    $map->put(7, 42);
    my $got = shm_ii_cas_take $map, 7, 42;
    is($got, 42, 'II cas_take kw: returns removed value');
    ok(!$map->exists(7), 'II cas_take kw: key removed');
    unlink $path;
}

# remove_multi
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    $map->put($_, $_ * 10) for 1..5;
    is($map->size, 5, 'remove_multi setup: 5 keys');
    is($map->remove_multi(1, 3, 99), 2, 'II remove_multi: 2 removed, 1 missing');
    is($map->size, 3, 'II remove_multi: size updated');
    ok(!$map->exists(1), 'II remove_multi: key 1 gone');
    ok($map->exists(2), 'II remove_multi: key 2 retained');
    ok(!$map->exists(3), 'II remove_multi: key 3 gone');
    # Empty call
    is($map->remove_multi(), 0, 'II remove_multi: empty list returns 0');
    unlink $path;
}

# remove_multi: SS (string keys)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 100);
    $map->put($_, "v$_") for qw(a b c d);
    is($map->remove_multi("a", "c", "missing"), 2, 'SS remove_multi: 2 removed');
    is($map->size, 2, 'SS remove_multi: size 2');
    ok($map->exists("b"), 'SS remove_multi: b retained');
    ok($map->exists("d"), 'SS remove_multi: d retained');
    unlink $path;
}

# get_with_ttl: TTL-less map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    $map->put(1, 100);
    my @r = $map->get_with_ttl(1);
    is_deeply(\@r, [100, undef], 'II get_with_ttl no-TTL: (value, undef)');
    my @miss = $map->get_with_ttl(99);
    is_deeply(\@miss, [], 'II get_with_ttl: empty list on missing');
    unlink $path;
}

# get_with_ttl: TTL map, permanent + per-key TTL
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::IS->new($path, 100, 0, 30);
    $map->put(1, "hello");
    my ($v, $t) = $map->get_with_ttl(1);
    is($v, "hello", 'IS get_with_ttl: value');
    ok($t > 0 && $t <= 30, "IS get_with_ttl: TTL within default (t=$t)");

    $map->persist(1);
    my ($v2, $t2) = $map->get_with_ttl(1);
    is($v2, "hello", 'IS get_with_ttl: value after persist');
    is($t2, 0, 'IS get_with_ttl: 0 = permanent');

    $map->put_ttl(2, "world", 90);
    my ($v3, $t3) = $map->get_with_ttl(2);
    is($v3, "world", 'IS get_with_ttl: value with per-key TTL');
    ok($t3 > 30 && $t3 <= 90, "IS get_with_ttl: per-key TTL (t=$t3)");
    unlink $path;
}

# get_with_ttl: expired entry returns empty list
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100, 0, 30);
    $map->put_ttl(1, 100, 1);
    sleep 2;
    my @r = $map->get_with_ttl(1);
    is_deeply(\@r, [], 'get_with_ttl: empty on expired');
    unlink $path;
}

# get_with_ttl: SI string-key
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 100, 0, 60);
    $map->put("k", 42);
    my ($v, $t) = $map->get_with_ttl("k");
    is($v, 42, 'SI get_with_ttl: value');
    ok($t > 0 && $t <= 60, "SI get_with_ttl: TTL (t=$t)");
    unlink $path;
}

done_testing;
