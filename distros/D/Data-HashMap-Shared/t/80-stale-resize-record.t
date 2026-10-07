use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::II;

# A resize records its progress in the header, and whoever recovers a dead
# resizer's lock finishes it.  Only the write section that made a record can
# be finishing it: one left behind by a recovery that ignored it (an older
# release's) must be dropped, or it re-places every tombstone as a live entry
# and moves the table to a capacity its live entries were never rehashed for.
# A record that cannot be finished must be dropped too, not spun on under the
# lock.  Each recovery runs in a child under a no-handler alarm, as in t/68.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/rz.shm";

sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 8; eval { $code->() }; POSIX::_exit($@ ? 2 : 0) }
    waitpid $pid, 0;
    return ($? & 127) == 14 ? 'hung' : $? & 127 ? 'signal' : ($? >> 8) == 2 ? 'died' : 'ok';
}

# Header offsets: table_cap 20, seq 64, rz_phase 99, rz_old_log2 108,
# rz_new_log2 109, rz_move 112, rz_cursor 120, rz_seq 124, wlock 128.
sub peek {
    my ($off, $fmt, $len) = @_;
    open my $fh, '<:raw', $path or die $!;
    seek $fh, $off, 0 or die $!;
    read $fh, my $raw, $len or die "short read";
    return unpack $fmt, $raw;
}
sub lg { my ($v) = @_; my $l = 0; $l++ while (1 << $l) < $v; $l }

my @live = grep { $_ % 9 } 1 .. 900;
my @gone = grep { !($_ % 9) } 1 .. 900;

sub fresh_map {
    unlink $path;
    my $m = Data::HashMap::Shared::II->new($path, 4096);
    $m->put($_, $_ * 10) for 1 .. 900;
    $m->remove($_) for @gone;
}

# A record for a resize to 2**$new_log2 in $phase, left by a writer of ours that
# died mid-publish; $bound says whether it names that writer's write section.
sub forge {
    my ($phase, $new_log2, $bound) = @_;
    open my $fh, '+<:raw', $path or die $!;
    my $poke = sub { seek $fh, $_[0], 0 or die $!; print $fh pack $_[1], $_[2] };
    my $seq = peek(64, 'L', 4) | 1;
    $poke->(64,  'L', $seq);
    $poke->(108, 'C', lg(peek(20, 'L', 4)));
    $poke->(109, 'C', $new_log2);
    $poke->(112, 'Q', 0);
    $poke->(120, 'L', 0);
    $poke->(124, 'L', $bound ? $seq : $seq + 2);
    $poke->(99,  'C', $phase);
    $poke->(128, 'L', 0x80000000 | $$);
    close $fh or die $!;
}

sub survivors {
    my $m = Data::HashMap::Shared::II->new($path, 4096);
    return (scalar(grep { ($m->get($_) // -1) == $_ * 10 } @live),
            scalar(grep { $m->exists($_) } @gone));
}

# A record another write section made, as an older release's recovery leaves it.
fresh_map();
my $cap = peek(20, 'L', 4);
is in_child(sub {
    forge(3, lg($cap) + 1, 0);
    Data::HashMap::Shared::II->new($path, 4096)->put(1000, 1);
}), 'ok', 'a recovery that finds a stale resize record completes';
my ($kept, $back) = survivors();
is $kept, scalar(@live), '  ... every live entry survives';
is $back, 0, '  ... and no removed entry comes back';
is peek(99, 'C', 1), 0, '  ... and the record is dropped';
is peek(20, 'L', 4), $cap, '  ... and the capacity is left alone';

# A record naming a capacity too small for what it has to place.
fresh_map();
is in_child(sub {
    forge(3, 4, 1);
    Data::HashMap::Shared::II->new($path, 4096)->put(1000, 1);
}), 'ok', 'a resize record that cannot be finished is dropped, not spun on';
is peek(99, 'C', 1), 0, '  ... and cleared';

# Control: a writer killed right after starting a grow is finished for it.
fresh_map();
$cap = peek(20, 'L', 4);
is in_child(sub {
    forge(1, lg($cap) + 1, 1);
    Data::HashMap::Shared::II->new($path, 4096)->put(1000, 1);
}), 'ok', 'a recovery finishes a resize its dead writer started';
($kept, $back) = survivors();
is $kept, scalar(@live), '  ... every live entry survives';
is $back, 0, '  ... and no removed entry comes back';
is peek(20, 'L', 4), 2 * $cap, '  ... and the table has grown';

# clear() records itself the same way.  A writer killed while it empties the
# states leaves the lower slots empty and the entries above them in place:
# listed, and unreachable past the emptied slots.  The next lock holder finishes
# the clear.
fresh_map();
$cap = peek(20, 'L', 4);
is in_child(sub {
    open my $fh, '+<:raw', $path or die $!;
    seek $fh, peek(48, 'Q', 8), 0 or die $!;
    print $fh "\0" x ($cap / 2);
    close $fh or die $!;
    forge(4, 0, 1);
    Data::HashMap::Shared::II->new($path, 4096)->put(1000, 1);
}), 'ok', 'a recovery finishes a clear its dead writer started';
{
    my $m = Data::HashMap::Shared::II->new($path, 4096);
    is join(',', $m->keys), '1000', '  ... leaving only what was stored after it';
    is $m->size, 1, '  ... with a size to match';
    ($kept) = survivors();
    is $kept, 0, '  ... and no entry of the cleared map';
    is peek(99, 'C', 1), 0, '  ... the record is cleared';
    cmp_ok peek(20, 'L', 4), '<', $cap, '  ... and the table is back at its initial capacity';
}

# A clear record another write section made must not clear the map.
fresh_map();
is in_child(sub {
    forge(4, 0, 0);
    Data::HashMap::Shared::II->new($path, 4096)->put(1000, 1);
}), 'ok', 'a recovery that finds a stale clear record completes';
($kept, $back) = survivors();
is $kept, scalar(@live), '  ... every live entry survives';
is $back, 0, '  ... and no removed entry comes back';
is peek(99, 'C', 1), 0, '  ... and the record is dropped';

done_testing;
