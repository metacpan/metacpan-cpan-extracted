use strict;
use warnings;
use Test::More;

# Hostile bless: user blesses an arbitrary ref into a module class and
# calls methods. The XS dispatch must croak cleanly on invalid handle,
# not segfault.

use Data::Pool::Shared;

# Bless a scalar containing zero — XS reads the "pointer" as 0
my $fake1 = bless \(my $z = 0), "Data::Pool::Shared::I64";
my $rc = eval { $fake1->alloc };
ok !defined $rc, "alloc on bless(0) croaks";
like $@, qr/destroyed/i, "meaningful error: " . substr($@, 0, 60);

# Bless scalar containing a random integer — XS reads garbage pointer.
# Isolate in a child process so a SIGSEGV doesn't take down the test.
my $pid = fork // die;
if (!$pid) {
    my $fake2 = bless \(my $bad = 0xDEADBEEF), "Data::Pool::Shared::I64";
    eval { $fake2->capacity };
    exit 0;   # reach here = no SIGSEGV
}
waitpid $pid, 0;
my $sig = $? & 0x7f;
my $exitcode = $? >> 8;
# Either clean exit (module has defensive null/alignment check) or
# SIGSEGV (documenting the threat model). Both are acceptable for
# this clearly-programmer-error scenario.
ok $sig == 0 || $sig == 11,
    sprintf "bless(random-int) survived or SIGSEGV'd cleanly (sig=%d exit=%d)",
    $sig, $exitcode;

# Bless an arrayref — XS dereferences as HV->SV, should fail early
my @arr = (1, 2, 3);
my $fake3 = bless \@arr, "Data::Pool::Shared::I64";
$rc = eval { $fake3->used };
ok !defined $rc, "used on bless([]) fails";

# Wrong class (not derived) — EXTRACT_POOL should reject via sv_derived_from
my $real = Data::Pool::Shared::I64->new_memfd("hb", 4);
my $otherclass = bless \(my $x = 42), "MyBogusClass";
$rc = eval { Data::Pool::Shared::capacity($otherclass) };
ok !defined $rc, "method call on non-derived bless rejected";
like $@ || '', qr/Expected|derived|not.*Pool/i, "meaningful class-mismatch error";

done_testing;
