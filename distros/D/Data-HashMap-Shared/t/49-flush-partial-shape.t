use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp qw(tempdir);

# flush_expired_partial returns ($flushed, $done), and the XSUB is written ten
# times over.  Drive every variant through a full expiry cycle and pin each
# value to what only IT can be: the first sums to the expired count, the
# second is 0 or 1 and true exactly once.

my @variants = qw(II IS SI SS I16 I16S I32 I32S SI16 SI32);
my $dir = tempdir(CLEANUP => 1);
my %map;
for my $v (@variants) {
    my $cls = "Data::HashMap::Shared::$v";
    eval "require $cls; 1" or die $@;
    my $m = $cls->new("$dir/fep-$v.shm", 64, 0, 60);   # count under a long TTL first
    $m->put($_, $_) for 1 .. 30;
    is $m->size, 30, "$v: 30 live entries before expiry";
    $m->set_ttl($_, 1) for 1 .. 30;
    $map{$v} = $m;
}
Time::HiRes::sleep(1.2);                                               # everything expires, once

for my $v (@variants) {
    my $m = $map{$v};
    my ($sum_first, $sum_second, $calls, $shape_bad, $range_bad) = (0, 0, 0, 0, 0);
    while (1) {
        my @r = $m->flush_expired_partial(8);
        $calls++;
        $shape_bad++ unless @r == 2;
        my ($n, $d) = @r;
        $range_bad++ unless defined $n && defined $d && $n =~ /^\d+$/ && $n <= 8 && ($d eq '0' || $d eq '1');
        $sum_first  += $n // 0;
        $sum_second += $d // 0;
        last if $d || $calls > 1000;
    }
    is $shape_bad,  0,  "$v: every call returned exactly two values ($calls calls)";
    is $range_bad,  0,  "$v: first value in 0..limit, second value exactly 0 or 1";
    is $sum_first,  30, "$v: the first value sums to the 30 expired entries";
    is $sum_second, 1,  "$v: the second value was true once, on the final call";
    is $m->size,    0,  "$v: table empty afterwards";
}

# flush_expired covers the whole table, wherever a partial flush -- this
# process's or another's -- left the shared cursor.
{
    my $m = Data::HashMap::Shared::SI->new(undef, 1000, 0, 2);
    $m->put("k$_", $_) for 1 .. 500;
    $m->flush_expired_partial($m->capacity / 2);    # nothing has expired: only moves the cursor
    Time::HiRes::sleep(2.1);
    is $m->flush_expired, 500, 'flush_expired after a partial flush expires all 500';
    is $m->size, 0, '  ... leaving the map empty';
}

# A cycle whose last slice expires nothing still shrinks a table its earlier
# slices emptied.
{
    my $m = Data::HashMap::Shared::II->new(undef, 10_000, 0, 60);
    $m->reserve(8000);
    my $cap = $m->capacity;
    $m->put_ttl($_, $_, 1) for 1 .. 100;
    Time::HiRes::sleep(1.2);
    my ($n, $d) = $m->flush_expired_partial($cap - 1);   # all but the last slot
    ok !$d, "the first slice of $cap - 1 slots does not end the cycle";
    ($n, $d) = $m->flush_expired_partial($cap - 1);      # the last slot alone
    ok $d, 'the second ends it';
    is $m->size, 0, 'every expired entry was flushed';
    cmp_ok $m->capacity, '<', $cap, "and the table shrank from $cap slots";
}

# Two flushers share the cursor, and the one whose slices never reach the
# table's end still learns that the cycle ended.
{
    my $path = "$dir/two-flushers.shm";
    my $low = Data::HashMap::Shared::II->new($path, 64, 0, 60);
    $low->put($_, $_) for 1 .. 30;
    my $high = Data::HashMap::Shared::II->new($path, 64, 0, 60);
    my $half = $low->capacity / 2;
    my (@low_done, @high_done);
    for (1 .. 3) {
        push @low_done,  ($low->flush_expired_partial($half))[1];    # the lower half, every time
        push @high_done, ($high->flush_expired_partial($half))[1];   # the upper half, to the end
    }
    is "@high_done", '1 1 1', 'the flusher that reaches the end of the table reports each cycle done';
    is "@low_done",  '0 1 1', 'and so does the other, once it finds the cursor back behind it';
    is $low->size, 30, 'nothing unexpired was flushed';
}
done_testing;
