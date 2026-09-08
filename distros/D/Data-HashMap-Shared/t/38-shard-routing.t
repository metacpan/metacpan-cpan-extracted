use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Shard routing used the low hash bits -- the same bits the in-shard probe uses
# -- so within a shard only capacity/num_shards home slots were reachable and
# probe runs grew with the shard count.  Routing now uses the high half of the
# 64-bit hash, which the slot index never looks at.
#
# That moves keys between shard FILES, which cannot be done in place, so the
# choice is recorded per set in a header byte carved from the reserved pad.  A
# set written before 0.20 reads 0 there and keeps its original placement.

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
my $ROUTING_OFF    = 97;
my $SHARD_LOG2_OFF = 98;

sub header_byte {
    my ($path, $off) = @_;
    open my $fh, '<', $path or die "$path: $!";
    sysseek $fh, $off, 0; sysread $fh, my $b, 1; close $fh;
    return unpack 'C', $b;
}
sub set_header_byte {
    my ($path, $off, $v) = @_;
    open my $fh, '+<', $path or die "$path: $!";
    sysseek $fh, $off, 0; syswrite $fh, pack 'C', $v; close $fh;
}

# --- new sets are stamped, and every key round-trips at any shard count ------
for my $shards (1, 4, 64, 1024) {
    my $p = "$dir/r" . $seq++;
    my $m = Data::HashMap::Shared::II->new_sharded($p, $shards, 40_000);
    is header_byte("$p.0", $ROUTING_OFF), 1, "$shards shards: new set stamped as split routing";
    $m->put($_, $_ * 7) for 1 .. 5_000;
    my $bad = grep { ($m->get($_) // -1) != $_ * 7 } 1 .. 5_000;
    is $bad, 0, "  ... all 5000 keys round-trip";
    my @k = $m->keys;
    is scalar @k, 5_000, "  ... and all are enumerable";
}

# --- a cursor seek must land in the same shard the dispatcher chose ----------
{
    my $m = Data::HashMap::Shared::SS->new_sharded("$dir/seek", 64, 40_000);
    $m->put("k$_", "v$_") for 1 .. 5_000;
    my $cur = $m->cursor;
    my $bad = 0;
    for my $i (1, 77, 512, 3000, 4999) {
        unless ($cur->seek("k$i")) { $bad++; next }
        my ($k) = $cur->next;
        $bad++ unless defined $k && $k eq "k$i";
    }
    is $bad, 0, 'cursor seek routes to the same shard as the dispatcher';
}

# --- the handle follows the FILE, not the build -----------------------------
# Keys placed under split routing, then the byte forced to legacy: if the handle
# ignored the byte every key would still be found, so a low count here is the
# proof that a genuine pre-0.20 set gets its own routing.
{
    my $p = "$dir/legacy";
    my $m = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    $m->put($_, $_) for 1 .. 2_000;
    undef $m;

    set_header_byte("$p.$_", $ROUTING_OFF, 0) for 0 .. 7;
    my $as_legacy = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    my $found = grep { defined $as_legacy->get($_) } 1 .. 2_000;
    cmp_ok $found, '<', 2_000, 'the routing byte is read from the file, not compiled in';
    undef $as_legacy;

    set_header_byte("$p.$_", $ROUTING_OFF, 1) for 0 .. 7;
    my $back = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    is scalar(grep { defined $back->get($_) } 1 .. 2_000), 2_000,
        '  ... and the set is intact under its own routing';
}

# --- a single-file map is unaffected either way -----------------------------
{
    my $m = Data::HashMap::Shared::II->new("$dir/plain.shm", 5_000);
    $m->put($_, $_) for 1 .. 2_000;
    is scalar(grep { defined $m->get($_) } 1 .. 2_000), 2_000,
        'a non-sharded map is unaffected by routing';
}


# --- shards must agree with each other ---------------------------------------
# Nothing checked this, so a shard file left by an earlier run with different
# settings was adopted silently: each key then followed whichever shard it
# routed to, while the summed accessors reported a figure belonging to no shard.
{
    my $p = "$dir/mixed";
    Data::HashMap::Shared::II->new("$p.1", 100);          # no TTL, no max_size
    my $ok = eval { Data::HashMap::Shared::II->new_sharded($p, 2, 100, 50, 60); 1 };
    my $err = $@ || '';
    ok !$ok, 'a set whose shards disagree is refused';
    like $err, qr/disagrees with .* on max_size/, '  ... naming the file and the field';

    my $q = "$dir/agree";
    ok eval { Data::HashMap::Shared::II->new_sharded($q, 4, 100, 50, 60); 1 },
        'a set created together opens';
    ok eval { Data::HashMap::Shared::II->new_sharded($q, 4, 100, 50, 60); 1 },
        '  ... and reopens';
    ok eval { Data::HashMap::Shared::II->new_sharded($q, 4, 999, 7, 3); 1 },
        '  ... and reopens with different arguments, which attach ignores';
}


# --- the shard count is recorded, so a wrong one is refused ------------------
# No single shard can imply the count, and opening a set with the wrong one hid
# the keys that routed elsewhere and orphaned every key written afterwards.
{
    my $p = "$dir/count";
    my $m = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    $m->put($_, $_) for 1 .. 2_000;
    undef $m;
    is header_byte("$p.0", $ROUTING_OFF), 1, 'the set routes on the high half';
    is header_byte("$p.0", $SHARD_LOG2_OFF), 4, 'the set records log2(8)+1';

    ok eval { Data::HashMap::Shared::II->new_sharded($p, 8, 40_000); 1 },
        'reopening with the right count works';
    for my $wrong (4, 16, 3) {
        my $ok = eval { Data::HashMap::Shared::II->new_sharded($p, $wrong, 40_000); 1 };
        my $err = $@ || '';
        ok !$ok, "reopening with $wrong shards is refused";
        like $err, qr/created with 8 shards/, "  ... saying what it was created with";
    }
    is scalar(my @f = glob "$p.*"), 8, 'a refused open notices at shard 0 and creates no extra files';

    my $back = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    is scalar(grep { defined $back->get($_) } 1 .. 2_000), 2_000, 'every key survived';
}

# a set predating the stamp keeps its old behaviour rather than having whatever
# count the caller passed cemented into it
{
    my $p = "$dir/nostamp";
    my $m = Data::HashMap::Shared::II->new_sharded($p, 4, 40_000);
    $m->put($_, $_) for 1 .. 100;
    undef $m;
    set_header_byte("$p.$_", $ROUTING_OFF, 0) for 0 .. 3;         # legacy routing
    set_header_byte("$p.$_", $SHARD_LOG2_OFF, 0) for 0 .. 3;   # and no recorded count
    ok eval { Data::HashMap::Shared::II->new_sharded($p, 4, 40_000); 1 },
        'a legacy set still opens with its own count';
    is header_byte("$p.0", $SHARD_LOG2_OFF), 0,
        '  ... and is not stamped retroactively';
}

# a legacy set opened with too many shards is refused because the new shards
# disagree on routing; it must not leave the whole extra half behind first
{
    my $p = "$dir/legacy_over";
    my $m = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    undef $m;
    set_header_byte("$p.$_", $ROUTING_OFF, 0)    for 0 .. 7;
    set_header_byte("$p.$_", $SHARD_LOG2_OFF, 0) for 0 .. 7;
    my $leg = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    $leg->put($_, $_) for 1 .. 200;   # populated after the stamp, so placement matches
    undef $leg;

    ok !eval { Data::HashMap::Shared::II->new_sharded($p, 16, 40_000); 1 },
        'a legacy set opened with too many shards is refused';
    like $@, qr/disagrees with .* on routing/, '  ... naming the routing disagreement';
    is scalar(my @f = glob "$p.*"), 9,
        '  ... having created only the shard it had to open to notice';

    my $back = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
    is scalar(grep { defined $back->get($_) } 1 .. 200), 200,
        '  ... and the original set is intact';
}


# When shard 0 is the missing one it is recreated carrying no count, so the
# mismatch is caught on a later shard -- and the message must name that file
# rather than speak for the whole set, which is what it used to do.
{
    my $p = "$dir/count0";
    { my $m = Data::HashMap::Shared::II->new_sharded($p, 8, 40_000);
      $m->put($_, $_) for 1 .. 100 }
    unlink "$p.0" or die "unlink: $!";

    ok !eval { Data::HashMap::Shared::II->new_sharded($p, 16, 40_000); 1 },
        'a wrong count is refused even when shard 0 was recreated';
    like $@, qr/\Q$p\E\.1 records 8 shards, not 16/,
        '  ... naming the shard that records the count';
    ok eval { Data::HashMap::Shared::II->new_sharded($p, 8, 40_000); 1 },
        '  ... and the set still opens at its true count';
}

done_testing;
