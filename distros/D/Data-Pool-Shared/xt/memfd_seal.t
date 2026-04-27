use strict;
use warnings;
use Test::More;
use Fcntl qw(F_GETFD FD_CLOEXEC);

# Verify memfd is created with F_SEAL_SHRINK | F_SEAL_GROW so malicious
# SCM_RIGHTS peers cannot ftruncate the backing region into SIGBUS.

use constant {
    F_GET_SEALS   => 1034,
    F_ADD_SEALS   => 1033,
    F_SEAL_SEAL   => 0x0001,
    F_SEAL_SHRINK => 0x0002,
    F_SEAL_GROW   => 0x0004,
    F_SEAL_WRITE  => 0x0008,
};

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("seal", 4);
ok $p, "memfd pool created";

my $fd = $p->memfd;
ok $fd >= 0, "got memfd fd=$fd";

# Read seals: open fd as a filehandle so fcntl works
open(my $fh, '<&=', $fd) or die "fdopen: $!";
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok defined $seals, "F_GET_SEALS returned $seals";

ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK is set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW is set";

# Adversarial ftruncate must fail with EPERM
my $rc = truncate($fh, 0);
ok !$rc, "truncate() on sealed memfd fails";
like "$!", qr/(permitted|denied)/i, "EPERM/EACCES error: $!";

# Normal operations still work
my $s = $p->alloc;
$p->set($s, 12345);
is $p->get($s), 12345, "operations still work after sealing";

done_testing;
