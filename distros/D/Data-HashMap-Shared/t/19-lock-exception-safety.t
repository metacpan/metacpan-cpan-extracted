use strict;
use warnings;
use Test::More;
use POSIX ':sys_wait_h';
use File::Temp ();

# Batch writes call SvIV/SvPV on caller SVs while holding the write lock and
# seqlock, and a tied or overloaded argument can die() inside that loop: the
# longjmp must not abandon the lock with the seqlock left odd, which
# self-deadlocks the process on its next op, recovery never firing for a live
# pid.  Each case runs in a child with a wall-clock deadline -- a real leak
# hangs in a futex syscall that Perl's alarm cannot interrupt.

# Overloaded object whose numification AND stringification die — exercises
# both the SvIV (integer-key/value) and SvPV (string-key/value) paths.
package Bomb;
use overload '0+' => sub { die "boom\n" },
             '""' => sub { die "boom\n" },
             fallback => 1;
sub new { bless {}, shift }

package main;

# Returns 1 iff $code (run in a child) finishes within $timeout AND exits 0.
sub child_ok {
    my ($timeout, $code) = @_;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if ($pid == 0) {
        $code->();
        POSIX::_exit(0);          # bypass END/DESTROY noise in the child
    }
    my $deadline = time + $timeout;
    while (time < $deadline) {
        my $w = waitpid($pid, WNOHANG);
        return ($? == 0) if $w == $pid;
        select undef, undef, undef, 0.05;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
    return 0;                      # had to be killed => deadlocked
}

# class => [ good-key, good-val-a, good-val-b ] with type-correct samples.
my @variants = (
    [ 'Data::HashMap::Shared::II', 1,   10,  20  ],  # int  key, int  val (SvIV/SvIV)
    [ 'Data::HashMap::Shared::SS', 'a', 'x', 'y' ],  # str  key, str  val (SvPV/SvPV)
    [ 'Data::HashMap::Shared::IS', 1,   'x', 'y' ],  # int  key, str  val (SvIV/SvPV)
    [ 'Data::HashMap::Shared::SI', 'a', 10,  20  ],  # str  key, int  val (SvPV/SvIV)
);

for my $v (@variants) {
    my ($class, $k, $va, $vb) = @$v;
    eval "require $class" or die "cannot load $class: $@";

    my $ok = child_ok(10, sub {
        my $dir = File::Temp->newdir;
        my $f   = "$dir/m.shm";
        my $m   = $class->new($f, 1000);

        # 1) die in set_multi with the bomb as a KEY (mid-loop, lock held)
        my $died = !eval { $m->set_multi($k, $va, Bomb->new, $vb); 1 };
        die "set_multi(bomb-key) did not die\n" unless $died && $@ =~ /boom/;

        # 2) the lock must be free now: this write must not hang
        $m->set_multi($k, $va);

        # 3) die in set_multi with the bomb as a VALUE
        $died = !eval { $m->set_multi($k, Bomb->new); 1 };
        die "set_multi(bomb-val) did not die\n" unless $died && $@ =~ /boom/;
        $m->set_multi($k, $vb);

        # 4) die in remove_multi with the bomb as a KEY (this also removes
        #    the real key $k that precedes the bomb, then dies)
        $died = !eval { $m->remove_multi($k, Bomb->new); 1 };
        die "remove_multi(bomb-key) did not die\n" unless $died && $@ =~ /boom/;

        # 5) lock + seqlock must be usable: re-set and read back (a leaked
        #    odd seqlock would make this get() spin forever)
        $m->set_multi($k, $vb);
        my $got = $m->get($k);
        die "get after recovery returned wrong value\n"
            unless defined $got && "$got" eq "$vb";

        # 6) a final batch op for good measure
        $m->remove_multi($k);
    });

    ok($ok, "$class: set_multi/remove_multi release the lock when an argument dies");
}

done_testing;
