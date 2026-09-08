use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Time::HiRes ();

use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SS;

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, $_[0]) }

my @variants = qw(I16 I32 II I16S I32S IS SI16 SI32 SI SS);
sub kv { my $v = shift; ($v =~ /^S/ ? ('dying', 'living') : (11, 22)), ($v =~ /S$/ ? 'val' : 5) }

# get_multi inlines its own probe in every variant file; it must agree with
# get() about an expired key, plain and sharded.
my %maps;
for my $v (@variants) {
    my $pkg = "Data::HashMap::Shared::$v";
    my ($k1, $k2, $val) = kv($v);
    for my $shards (0, 4) {
        my $map = $shards ? $pkg->new_sharded(path("$v-s"), $shards, 100, 0, 1)
                          : $pkg->new(path("$v.shm"), 100, 0, 1);   # 1s default TTL
        ok $map->put_ttl($k1, $val, 1), "$v" . ($shards ? ' sharded' : '') . ": put_ttl 1s";
        ok $map->put_ttl($k2, $val, 0), "$v" . ($shards ? ' sharded' : '') . ": put_ttl permanent";
        # the 1s key can already be dead on a coarse clock; check liveness on the
        # permanent one
        my ($m2) = $map->get_multi($k2);
        is $m2, $map->get($k2), "$v" . ($shards ? ' sharded' : '') . ": get_multi agrees with get while alive";
        is $m2, $val, "$v" . ($shards ? ' sharded' : '') . ": ... and it is the value";
        $maps{"$v/$shards"} = $map;
    }
}
# CLOCK_MONOTONIC_COARSE seconds: 1.6s past the insert the second has ticked at least once
Time::HiRes::sleep(1.6);
for my $v (@variants) {
    my ($k1, $k2, $val) = kv($v);
    for my $shards (0, 4) {
        my $name = "$v" . ($shards ? ' sharded' : '');
        my $map = $maps{"$v/$shards"};
        my ($m1, $m2) = $map->get_multi($k1, $k2);
        my ($g1, $g2) = ($map->get($k1), $map->get($k2));
        ok !defined $g1, "$name: get() reports the expired key absent";
        ok !defined $m1, "$name: get_multi() reports the expired key absent";
        is $m2, $g2, "$name: get_multi agrees with get on the permanent key";
        is $m2, $val, "$name: ... which is still there";
    }
}

# Keys outside a narrow variant's range are truncated to the low bits; get and
# get_multi must land on the same entry for the same out-of-range key.
my %wide = (
    I16  => [4464, [70000, 131072 + 4464, 4464 - 65536, 2**31 + 4464, -2**40 + 4464]],
    I16S => [4464, [70000, 131072 + 4464, 4464 - 65536, 2**31 + 4464, -2**40 + 4464]],
    # 74565 = 0x12345 has bits above 16, so over-narrowing to int16 changes it
    I32  => [74565, [2**32 + 74565, 2**33 + 74565, 74565 - 2**32, 2**40 + 74565, -2**48 + 74565]],
    I32S => [74565, [2**32 + 74565, 2**33 + 74565, 74565 - 2**32, 2**40 + 74565, -2**48 + 74565]],
);
for my $v (sort keys %wide) {
    my ($stored, $probes) = @{ $wide{$v} };
    my $val = $v =~ /S$/ ? 'wide' : 9;
    for my $shards (0, 4) {
        my $name = "$v" . ($shards ? ' sharded' : '');
        my $pkg = "Data::HashMap::Shared::$v";
        my $map = $shards ? $pkg->new_sharded(path("$v-w"), $shards, 100)
                          : $pkg->new(path("$v-w.shm"), 100);
        ok $map->put($stored, $val), "$name: put($stored)";
        for my $k (@$probes) {
            my ($m) = $map->get_multi($k);
            my $g = $map->get($k);
            is $g, $val, "$name: get($k) finds the truncated key";
            is $m, $g, "$name: get_multi($k) agrees with get";
        }
        my @m = $map->get_multi(@$probes);
        is_deeply \@m, [ map { $map->get($_) } @$probes ], "$name: batched get_multi agrees with get";
    }
}

done_testing;
