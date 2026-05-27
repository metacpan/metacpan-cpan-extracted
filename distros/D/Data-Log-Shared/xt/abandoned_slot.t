use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Fcntl qw(SEEK_SET);
use Time::HiRes ();
use Data::Log::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Targeted test for v0.04 abandoned-slot recovery. The kill-mid-op test
# (kill_midop.t) almost never hits the narrow window between CAS-reserve
# and len-commit; here we directly zero the len field of a committed
# entry to simulate the writer crashing post-CAS, pre-commit.

my $path = tmpnam() . '.log';

# --- 1. Middle-slot abandonment is skipped, surrounding entries intact ---
{
    my $log = Data::Log::Shared->new($path, 4096);
    my $off1 = $log->append("first");
    my $off2 = $log->append("second");
    my $off3 = $log->append("third");
    $log->sync;
    undef $log;

    # Header is 128 bytes (sizeof LogHeader). len lives at slot+4.
    open my $fh, '+<:raw', $path or die $!;
    seek($fh, 128 + $off2 + 4, SEEK_SET);
    syswrite($fh, pack("V", 0), 4) == 4 or die "syswrite: $!";
    close $fh;

    my $log2 = Data::Log::Shared->new($path, 4096);
    my ($d1, $n1) = $log2->read_entry($off1, 0);
    is $d1, "first", "first entry intact";

    my ($d2, $n2) = $log2->read_entry($off2, 0);
    ok defined $n2, "abandoned slot returns next_off";
    ok !defined $d2, "abandoned slot returns undef data";
    is $n2, $off3, "abandoned next_off advances past slot";

    my ($d3, $n3) = $log2->read_entry($off3, 0);
    is $d3, "third", "entry after abandoned slot intact";

    # each_entry skips the abandoned slot silently (pass 0 wait to be fast)
    my @seen;
    $log2->each_entry(sub { push @seen, $_[0] }, 0, 0);
    is_deeply \@seen, ["first", "third"], "each_entry skips abandoned";
}
unlink $path;

# --- 2. Reserve_size==0 (writer died before publishing it) -> EMPTY ---
{
    my $log = Data::Log::Shared->new($path, 4096);
    my $off1 = $log->append("alpha");
    my $off2 = $log->append("beta");
    my $off3 = $log->append("gamma");
    $log->sync;
    undef $log;

    # Zero BOTH reserve_size and len of slot 2 to simulate the rarer case:
    # writer died between CAS and reserve_size store.
    open my $fh, '+<:raw', $path or die $!;
    seek($fh, 128 + $off2, SEEK_SET);
    syswrite($fh, pack("V V", 0, 0), 8) == 8 or die "syswrite: $!";
    close $fh;

    my $log2 = Data::Log::Shared->new($path, 4096);
    my @r = $log2->read_entry($off2, 0);
    is scalar @r, 0, "reserve_size=0 returns EMPTY (caller must give up)";

    # each_entry terminates at the unrecoverable gap (pass 0 wait to be fast)
    my @seen;
    $log2->each_entry(sub { push @seen, $_[0] }, 0, 0);
    is_deeply \@seen, ["alpha"], "each_entry stops at unrecoverable gap";
}
unlink $path;

# --- 3. abandon_wait_us parameter: 0 = immediate skip ---
{
    my $log = Data::Log::Shared->new($path, 4096);
    my $off1 = $log->append("aa");
    my $off2 = $log->append("bb");
    $log->sync;
    undef $log;

    open my $fh, '+<:raw', $path or die $!;
    seek($fh, 128 + $off1 + 4, SEEK_SET);
    syswrite($fh, pack("V", 0), 4) == 4 or die "syswrite: $!";
    close $fh;

    my $log2 = Data::Log::Shared->new($path, 4096);
    my $t0 = Time::HiRes::time();
    my ($d, $n) = $log2->read_entry($off1, 0);
    my $elapsed = Time::HiRes::time() - $t0;
    ok $elapsed < 0.05, "abandon_wait_us=0 returns immediately (took ${elapsed}s)";
    ok defined $n, "got next_off";
    ok !defined $d, "got undef data";
}
unlink $path;

# --- 4. Truncated reserve_size (corrupt: too small or misaligned) -> EMPTY ---
{
    my $log = Data::Log::Shared->new($path, 4096);
    $log->append("xx");
    my $off2 = $log->append("yy");
    $log->sync;
    undef $log;

    # Corrupt reserve_size to a too-small value (e.g., 4 < LOG_ENTRY_HDR=8)
    # and zero len. Reader should treat as EMPTY, not advance into garbage.
    open my $fh, '+<:raw', $path or die $!;
    seek($fh, 128 + $off2, SEEK_SET);
    syswrite($fh, pack("V V", 4, 0), 8) == 8 or die "syswrite: $!";
    close $fh;

    my $log2 = Data::Log::Shared->new($path, 4096);
    my @r = $log2->read_entry($off2, 0);
    is scalar @r, 0, "too-small reserve_size returns EMPTY";

    # Corrupt to misaligned value
    open $fh, '+<:raw', $path or die $!;
    seek($fh, 128 + $off2, SEEK_SET);
    syswrite($fh, pack("V V", 13, 0), 8) == 8 or die "syswrite: $!";
    close $fh;

    my $log3 = Data::Log::Shared->new($path, 4096);
    my @r2 = $log3->read_entry($off2, 0);
    is scalar @r2, 0, "misaligned reserve_size returns EMPTY";
}
unlink $path;

done_testing;
