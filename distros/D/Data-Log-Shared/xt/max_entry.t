use strict;
use warnings;
use Test::More;
use Data::Log::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Max-size entry: exercises overflow guard in log_append's padded-size
# arithmetic. The bound is UINT32_MAX - LOG_ENTRY_HDR - 3.
# We use a moderately large (10 MB) entry — enough to exercise memcpy
# on large buffers without allocating 4 GB.
{
    my $size = 10 * 1024 * 1024;     # 10 MB
    my $log  = Data::Log::Shared->new(undef, $size * 2);
    my $data = "X" x $size;
    my $off  = $log->append($data);
    ok defined $off, 'append 10MB entry returns offset';
    is $off, 0, 'first entry at offset 0';
    my ($d, $next) = $log->read_entry(0);
    is length($d), $size, 'read 10MB entry length';
    is $d, $data, 'read 10MB entry content';
    cmp_ok $next, '>', $size, 'next offset past entry';
    cmp_ok $next % 4, '==', 0, 'next offset is 4-byte aligned (ARM64 fix)';
}

# Oversize: exceeds data_size — must return undef, not crash
{
    my $log = Data::Log::Shared->new(undef, 1024);
    my $toobig = "Y" x 2048;
    my $off = $log->append($toobig);
    ok !defined $off, 'oversize append returns undef';
    # Log is still usable
    ok defined $log->append("small"), 'log usable after rejected oversize';
}

# Large batch of variable-length entries: exercises padding math
{
    my $log = Data::Log::Shared->new(undef, 1024 * 1024);
    my $off;
    for my $n (1..9) {
        my $data = "x" x $n;      # varying small sizes; each len % 4 != 0
        my $this_off = $log->append($data);
        ok defined $this_off, "append len=$n";
        cmp_ok $this_off % 4, '==', 0, "offset $this_off is 4-aligned"
            if defined $this_off;
    }
}

done_testing;
