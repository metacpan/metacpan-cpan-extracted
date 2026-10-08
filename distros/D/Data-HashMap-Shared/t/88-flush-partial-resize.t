use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(sleep);

# A resize can move an entry behind the shared partial-flush cursor, also when
# another handle performs it; the scan must restart at zero rather than report a
# complete cycle.
my $dir = tempdir(CLEANUP => 1);
my @cases;
for my $variant (qw(II IS SI SS I16 I16S I32 I32S SI16 SI32)) {
    my $class = "Data::HashMap::Shared::$variant";
    eval "require $class; 1" or die $@;
    my $path = "$dir/$variant";
    my $m = $class->new($path, 1000, 0, 3600);
    $m->reserve(64) or die 'cannot reserve shrink fixture';
    $m->put_ttl($_, $_, 1) or die 'cannot seed shrink fixture' for 1 .. 31;
    $m->put_ttl(32, 32, 0) or die 'cannot seed permanent entry';
    my $writer = $class->new($path, 1000, 0, 3600);
    push @cases, [$variant, $m, $writer];
}

# Each pair collides at slot 15 in a 64-slot II table; on growth the first key
# hashes to 79 and the second stays at 15, so the probe run splits.  Also used
# for a same-capacity rehash.
my @high = qw(86 167 352 446 449 478 756 1025 1030 1200
              1481 1527 1623 1868 2004 2108 2289 2324 2338 2422);
my @low = qw(200 326 671 778 1077 1149 1211 1284 1322 1355
             1734 1787 1939 1981 2044 2072 2137 2157 2260 2433);
my @cluster = map { ($high[$_], $low[$_]) } 0 .. $#high;
my @rehashes;
for my $how (qw(grow compact)) {
    my $m = Data::HashMap::Shared::II->new(undef, 1000, 0, 3600);
    $m->reserve(47) or die 'cannot reserve collision fixture';
    my @keys = $how eq 'grow' ? @cluster[0 .. 19] : @cluster;
    $m->put_ttl($_, $_, 0) or die 'cannot seed collision fixture' for @keys;
    is_deeply [$m->keys], \@keys, "$how: the fixture forms one probe run";
    my $victim = $how eq 'grow' ? $keys[-1] : $keys[17];
    $m->set_ttl($victim, 1) or die 'cannot expire collision fixture';
    push @rehashes, [$how, $m, $victim];
}
sleep 1.2;

for my $case (@cases) {
    my ($variant, $m, $writer) = @$case;
    subtest "$variant: shrink from another handle restarts the scan" => sub {
        is $m->capacity, 128, 'the first slice starts in a 128-slot table';
        my ($total, $done) = $m->flush_expired_partial(16);
        ok !$done, 'the first slice leaves a scan in progress';
        ok $writer->remove(32), 'remove the permanent entry through another handle';
        cmp_ok $m->capacity, '<', 128, 'the removal shrinks the table';
        cmp_ok $m->capacity, '>', 16, 'the old cursor still fits inside the smaller table';
        my $calls = 0;
        while (!$done && ++$calls <= 128) {
            my $n;
            ($n, $done) = $m->flush_expired_partial(16);
            $total += $n;
        }
        ok $done, 'the restarted cycle finishes';
        is $total, 31, 'it reclaims every expired entry';
        is $m->size, 0, 'the table is empty when done is reported';
        is $m->flush_expired, 0, 'a full flush finds nothing left behind';
    };
}

for my $case (@rehashes) {
    my ($how, $m, $victim) = @$case;
    subtest "$how: relocating a probe run restarts the scan" => sub {
        my ($total, $done) = $m->flush_expired_partial(26);
        is $total, 0, 'the expired entry is above the first slice';
        ok !$done, 'the first slice leaves a scan in progress';
        if ($how eq 'grow') {
            ok $m->reserve(95), 'grow the table while the scan is in progress';
            is $m->capacity, 128, 'the probe run splits across the larger table';
        } else {
            $m->remove($_) for @cluster[0 .. 16];
            is $m->tombstones, 17, 'removing the prefix arms tombstone compaction';
            ok $m->put_ttl(10_000, 1, 0), 'the next store compacts the table';
            is $m->capacity, 64, 'the capacity stays the same';
            is $m->tombstones, 0, 'the probe run has been rehashed';
        }
        my $calls = 0;
        while (!$done && ++$calls <= 128) {
            my $n;
            ($n, $done) = $m->flush_expired_partial(26);
            $total += $n;
        }
        ok $done, 'the restarted cycle finishes';
        is $total, 1, 'it reclaims the entry relocated below the old cursor';
        is $m->flush_expired, 0, 'a full flush finds nothing left behind';
        ok !$m->exists($victim), 'the expired key remains absent';
    };
}

done_testing;
