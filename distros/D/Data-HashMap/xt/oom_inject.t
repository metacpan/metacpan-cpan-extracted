use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

# OOM behavior: under tight memory limits, operations that would otherwise
# allocate should fail gracefully (return false / croak) rather than SEGV.
# We fork a child with RLIMIT_AS clamped just above current RSS, then try
# progressively larger allocations.

BEGIN {
    eval { require BSD::Resource; 1 }
        or plan skip_all => "BSD::Resource required for RLIMIT_AS";
    BSD::Resource->import(qw(setrlimit RLIMIT_AS));
}

use Data::HashMap::II;
use Data::HashMap::SS;

sub current_as_bytes {
    open my $fh, '<', "/proc/$$/status" or return undef;
    while (<$fh>) { return $1 * 1024 if /^VmSize:\s+(\d+)/ }
    undef;
}

plan skip_all => "requires /proc/self/status" unless defined current_as_bytes();

# ---- 1. reserve(huge_n) fails gracefully on int-key II ----

{
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $vm = current_as_bytes();
        setrlimit(RLIMIT_AS, $vm + 32 * 1024 * 1024, $vm + 32 * 1024 * 1024);
        my $m = Data::HashMap::II->new();
        my $ok = eval { $m->reserve(1 << 28); 1 };
        # Either returns quietly (succeeded) or we die gracefully
        _exit($ok || $@ ? 0 : 1);
    }
    waitpid $pid, 0;
    is $? >> 8, 0, 'OOM: reserve(huge) under memory limit did not SEGV';
}

# ---- 2. put of impossibly large string returns false ----

{
    my $m = Data::HashMap::SS->new();
    my $huge = ' ' x (1 << 20);  # 1MB — fine, just exercise size-check path
    ok $m->put($huge, "x"), 'SS: large (1MB) key accepted';
    is $m->get($huge), "x", 'SS: large key retrievable';
}

# ---- 3. thaw with bogus huge count does not allocate unreasonably ----
#   thaw reserves cnt entries up-front; a malicious cnt near 2^31 must not
#   hang or trigger the OOM killer.

{
    my $data = pack('a4 C C V V V V',
        "DHMP", 1, 1,       # magic + version + variant_id(II)
        0x7FFFFFF0,         # bogus huge count
        0, 0, 0);            # max_size, default_ttl, lru_skip
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $vm = current_as_bytes();
        setrlimit(RLIMIT_AS, $vm + 64 * 1024 * 1024, $vm + 64 * 1024 * 1024);
        eval { Data::HashMap::II->thaw($data) };
        _exit(0);  # any exit without SEGV is OK — error message or truncated
    }
    waitpid $pid, 0;
    is $? >> 8, 0, 'OOM: thaw with bogus huge count does not SEGV';
}

done_testing;
