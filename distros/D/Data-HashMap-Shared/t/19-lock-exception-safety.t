use strict;
use warnings;
use Test::More;
use POSIX ':sys_wait_h';
use File::Temp ();

# A tied or overloaded argument can die() inside a batch write while the write
# lock and seqlock are held; the longjmp must not leave the seqlock odd, which
# self-deadlocks the process on its next op. Each case runs in a child with a
# wall-clock deadline: a real leak hangs in a futex syscall that alarm cannot
# interrupt.

# numification and stringification both die, covering the SvIV and SvPV paths
package Bomb;
use overload '0+' => sub { die "boom\n" },
             '""' => sub { die "boom\n" },
             fallback => 1;
sub new { bless {}, shift }

package main;

sub child_ok {
    my ($timeout, $code) = @_;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if ($pid == 0) {
        $code->();
        POSIX::_exit(0);          # bypass END/DESTROY in the child
    }
    my $deadline = time + $timeout;
    while (time < $deadline) {
        my $w = waitpid($pid, WNOHANG);
        return ($? == 0) if $w == $pid;
        select undef, undef, undef, 0.05;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
    return 0;
}

# class => [ good-key, good-val-a, good-val-b ] with type-correct samples.
my @variants = (
    [ 'Data::HashMap::Shared::II', 1,   10,  20  ],
    [ 'Data::HashMap::Shared::SS', 'a', 'x', 'y' ],
    [ 'Data::HashMap::Shared::IS', 1,   'x', 'y' ],
    [ 'Data::HashMap::Shared::SI', 'a', 10,  20  ],
);

for my $v (@variants) {
    my ($class, $k, $va, $vb) = @$v;
    eval "require $class" or die "cannot load $class: $@";

    my $ok = child_ok(10, sub {
        my $dir = File::Temp->newdir;
        my $f   = "$dir/m.shm";
        my $m   = $class->new($f, 1000);

        my $died = !eval { $m->set_multi($k, $va, Bomb->new, $vb); 1 };
        die "set_multi(bomb-key) did not die\n" unless $died && $@ =~ /boom/;

        $m->set_multi($k, $va);

        $died = !eval { $m->set_multi($k, Bomb->new); 1 };
        die "set_multi(bomb-val) did not die\n" unless $died && $@ =~ /boom/;
        $m->set_multi($k, $vb);

        # also removes the real key $k that precedes the bomb, then dies
        $died = !eval { $m->remove_multi($k, Bomb->new); 1 };
        die "remove_multi(bomb-key) did not die\n" unless $died && $@ =~ /boom/;

        # a leaked odd seqlock would make this get() spin forever
        $m->set_multi($k, $vb);
        my $got = $m->get($k);
        die "get after recovery returned wrong value\n"
            unless defined $got && "$got" eq "$vb";

        $m->remove_multi($k);
    });

    ok($ok, "$class: set_multi/remove_multi release the lock when an argument dies");
}

done_testing;
