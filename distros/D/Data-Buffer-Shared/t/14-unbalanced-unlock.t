use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Buffer::Shared::I64;

# An unbalanced unlock_rd (more unlocks than locks) must not decrement a reader
# slot this handle never incremented.  It used to: the slot's rdepth wrapped from
# 0 to UINT32_MAX, and because the owning pid is alive, dead-reader recovery never
# fires -- so every writer on the buffer, in every process, blocked forever inside
# the drain futex.  The hang is in a syscall under XS, so even Perl's alarm cannot
# break it; the process has to be killed.

my $dir = tempdir( CLEANUP => 1 );
my $p   = "$dir/unbalanced.i64";

my $b = Data::Buffer::Shared::I64->new( $p, 128 );

# Claim a reader slot and release it cleanly.
$b->lock_rd;
$b->unlock_rd;

# The write lock must still be obtainable at this point.
$b->lock_wr;
$b->unlock_wr;
pass 'write lock works after a balanced lock_rd/unlock_rd';

# One unlock too many: must be a no-op, not an underflow.
$b->unlock_rd;
$b->unlock_rd;
pass 'extra unlock_rd calls return';

# The reader slot must still read 0, not UINT32_MAX.
{
    open my $fh, '<', $p or die "open $p: $!";
    binmode $fh;
    seek $fh, 128, 0;                       # reader_slots_off == sizeof(BufHeader)
    read $fh, my $blob, 1024 * 16;          # BUF_READER_SLOTS * sizeof(BufReaderSlot)
    close $fh;
    my @bad;
    for my $i ( 0 .. 1023 ) {
        my ( $pid, $rdepth ) = unpack 'LL', substr( $blob, $i * 16, 8 );
        push @bad, "slot $i: pid=$pid rdepth=$rdepth" if $rdepth != 0;
    }
    is scalar @bad, 0, 'no reader slot left with a nonzero rdepth'
        or diag join "\n", @bad;
}

# And a writer must still be able to acquire.  If the underflow is back this
# blocks forever, so fence it with a child that we can kill.
{
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    unless ($pid) {
        my $c = Data::Buffer::Shared::I64->new( $p, 128 );
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
    ok $reaped, 'a writer in another process still acquires the write lock';
}

done_testing;
