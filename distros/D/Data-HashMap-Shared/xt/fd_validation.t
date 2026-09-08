use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;

# 1. /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::HashMap::Shared::II->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat|corrupt|bad magic|mismatch)/i, 'meaningful error';
}

# 2. A genuine file whose section offsets were corrupted at rest.  Built by the
# module, so nothing but the three offsets under test is pinned.
{
    my $dir  = tempdir(CLEANUP => 1);
    my $path = "$dir/good.shm";
    { my $m = Data::HashMap::Shared::II->new($path, 64); $m->put(1, 100); $m->sync }
    open my $fh, '<:raw', $path or die "open: $!";
    my $good = do { local $/; <$fh> };
    close $fh;

    my %off = (nodes_off => 40, states_off => 48, arena_off => 56);
    for my $field (sort keys %off) {
        my $bad = $good;
        substr($bad, $off{$field}, 8) = pack('Q<', ~0);
        my $p = "$dir/$field.shm";
        open my $out, '>:raw', $p or die "open: $!";
        print $out $bad;
        close $out or die "close: $!";
        open my $rfh, '+<', $p or die "open: $!";
        my $r = eval { Data::HashMap::Shared::II->new_from_fd(fileno($rfh)) };
        ok !defined($r), "$field outside the file is rejected";
        like $@, qr/corrupt/, "  ...as corrupt";
        close $rfh;
    }

    # The occupancy bitmap follows the reader-slot table and is bounded on its
    # own: a file short by up to its 128 bytes, total_size corrected to match,
    # keeps the reader slots inside the mapping and only the bitmap outside.
    for my $cut (1, 128) {
        my $bad = substr($good, 0, length($good) - $cut);
        substr($bad, 32, 8) = pack('Q<', length $bad);
        my $p = "$dir/occ$cut.shm";
        open my $out, '>:raw', $p or die "open: $!";
        print $out $bad;
        close $out or die "close: $!";
        open my $rfh, '+<', $p or die "open: $!";
        my $r = eval { Data::HashMap::Shared::II->new_from_fd(fileno($rfh)) };
        ok !defined($r), "a file $cut byte(s) short of the occupancy bitmap is rejected";
        like $@, qr/out of bounds/, "  ...as out of bounds";
        close $rfh;
    }
}

# 3. Roundtrip
{
    my $m = Data::HashMap::Shared::II->new_memfd("t", 64);
    my $m2 = Data::HashMap::Shared::II->new_from_fd($m->memfd);
    $m->put(1, 100);
    is $m2->get(1), 100, 'genuine valid hashmap still accepted';
}

done_testing;
