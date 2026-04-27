use strict;
use warnings;
use Test::More;
use Time::HiRes qw(usleep);
use POSIX qw(_exit);

# Parent-owner SIGKILL; child continues operating. Proves the child's
# ops don't depend on the parent's Handle (fd is duped via
# F_DUPFD_CLOEXEC in new_from_fd).

use Data::Pool::Shared;

pipe(my $r, my $w) or die;

my $grandparent = fork // die "fork: $!";
if ($grandparent) {
    # Outer test process: wait for grandchild report via pipe
    close $w;
    my $result = do { local $/; <$r> };
    close $r;
    waitpid $grandparent, 0;
    chomp $result;

    if ($result =~ /^ok:(\d+)$/) {
        is $1, 4242, "grandchild survived parent SIGKILL and read value";
    } else {
        fail "unexpected result: $result";
    }
    done_testing;
    exit;
}

# Inner process (parent): create pool, fork grandchild with fd
close $r;
my $p = Data::Pool::Shared::I64->new_memfd("ps", 4);
my $s = $p->alloc;
$p->set($s, 4242);
my $fd = $p->memfd;

my $gc = fork // die;
if (!$gc) {
    # Grandchild: reopen via new_from_fd (dups fd); wait for parent to die
    my $p2 = Data::Pool::Shared::I64->new_from_fd($fd);
    # Signal parent to die
    kill 'KILL', getppid();
    sleep 1;
    # Try reading; must still work (parent handle is gone, mmap stays)
    my $val = $p2->get($s);
    print $w "ok:$val";
    close $w;
    _exit(0);
}

# Parent: just wait to be killed by grandchild
sleep 10;
_exit(99);  # should never reach
