use strict;
use warnings;
use Test::More;
use Data::Graph::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Boundary/invalid-argument tests. Each should croak cleanly, not crash.

# Happy-path baseline: constructor works with sane args.
my $ok = eval { my $h = Data::Graph::Shared->new(undef, 64, 64); 1 };
ok $ok, 'baseline: valid args succeed' or diag "unexpected failure: $@";

# Each bad-arg case: the module either croaks cleanly or returns an object.
# What it must NOT do: crash with a signal (SIGSEGV / SIGABRT).
# We run each case in a child so we can detect signal termination.

sub run_child {
    my ($label, $code) = @_;
    my $pid = fork // die;
    if ($pid == 0) {
        eval { $code->(); };
        exit 0;  # any croak is fine — we only care about no signal
    }
    waitpid($pid, 0);
    my $sig = $? & 127;
    is $sig, 0, "$label: no signal death (wstat=$?)";
}

# --- path with embedded NUL (Perl may truncate; module may accept/reject) ---
run_child('embedded NUL path',     sub { Data::Graph::Shared->new("/tmp/a\x00b.shm", 16) });

# --- zero capacity ---
run_child('cap=0',                 sub { Data::Graph::Shared->new(undef, 0) });

# --- astronomically huge capacity (mmap may succeed reserving address space) ---
run_child('huge capacity',         sub { Data::Graph::Shared->new(undef, 2 ** 50) });

# --- new_from_fd with bogus fd ---
SKIP: {
    skip 'no new_from_fd', 2 unless Data::Graph::Shared->can('new_from_fd');
    run_child('new_from_fd(-1)', sub { Data::Graph::Shared->new_from_fd(-1) });
    eval { Data::Graph::Shared->new_from_fd(-1) };
    ok $@, "new_from_fd(-1) croaks (err: $@)";
}

done_testing;
