use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Buffer::Shared::I64;

# Reader slots are claimed per HANDLE, so more than BUF_READER_SLOTS handles in
# one process exhausts the table and pushes the surplus onto the slotless
# counter.  Releasing such a lock must decrement the counter it was published to.
# It used to decrement the handle's reader slot instead whenever the handle had
# since claimed one, which both underflowed that slot and stranded
# slotless_rdepth above zero -- nothing recovers either, so every writer blocked
# forever.

my $dir = tempdir( CLEANUP => 1 );
my $p   = "$dir/slotless.i64";

my $owner = Data::Buffer::Shared::I64->new( $p, 64 );

# total read depth recorded across every reader slot
sub slot_depth {
    open my $fh, '<', $p or die "open $p: $!";
    binmode $fh;
    seek $fh, 128, 0;                       # reader_slots_off == sizeof(BufHeader)
    read $fh, my $blob, 1024 * 16;          # BUF_READER_SLOTS * sizeof(BufReaderSlot)
    close $fh;
    my $sum = 0;
    for my $i ( 0 .. 1023 ) {
        my ( undef, $rdepth ) = unpack 'LL', substr( $blob, $i * 16, 8 );
        $sum += $rdepth;
    }
    return $sum;
}

my $N = 1100;                                # > BUF_READER_SLOTS (1024)
my @h = map { Data::Buffer::Shared::I64->new( $p, 64 ) } 1 .. $N;

$_->lock_rd   for @h;
$_->unlock_rd for @h;
is slot_depth(), 0, 'all slot depths back to zero after a slotless-overflow round';

# The interleaved case: take a lock while slotless, free slots so this handle can
# claim one, take a second lock, then release both.
my $x = $h[-1];
$x->lock_rd;                                 # table full -> slotless
undef @h[ 0 .. 199 ];                        # free 200 slots
$x->lock_rd;                                 # this one may land in a real slot
$x->unlock_rd;
$x->unlock_rd;
is slot_depth(), 0, 'no slot underflow when a slot is claimed mid-hold';

# And a writer in another process must still get through.
{
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    unless ($pid) {
        my $c = Data::Buffer::Shared::I64->new( $p, 64 );
        $c->lock_wr;
        $c->unlock_wr;
        exit 0;
    }
    my $reaped = 0;
    for ( 1 .. 100 ) {                       # 10s budget
        if ( waitpid( $pid, 1 ) == $pid ) { $reaped = 1; last }
        select undef, undef, undef, 0.1;
    }
    unless ($reaped) { kill 'KILL', $pid; waitpid $pid, 0 }
    ok $reaped, 'a writer still acquires after slotless readers have drained';
}

done_testing;
