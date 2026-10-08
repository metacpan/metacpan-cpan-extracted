use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_fork') . '.shm' }

# Workers wait on a pipe barrier so they reach the contested call together; a
# bare fork loop lets the first child finish before the last exists. Returns how
# many calls returned true.
sub race {
    my ($n, $open, $call) = @_;
    pipe(my $r, my $w) or die "pipe: $!";
    my @pids;
    for my $i (1 .. $n) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $w;
            my $h = $open->();
            <$r>;
            POSIX::_exit($call->($h, $i) ? 1 : 0);
        }
        push @pids, $pid;
    }
    close $r;
    close $w;
    local $SIG{ALRM} = sub { kill 'KILL', @pids; die "workers exceeded their time budget\n" };
    alarm 30;
    my ($true, $crashed) = (0, 0);
    for my $pid (@pids) {
        waitpid $pid, 0;
        if ($? & 127) { $crashed++ } else { $true += $? >> 8 }
    }
    alarm 0;
    is($crashed, 0, 'no worker died on a signal');
    return $true;
}

{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100);
    $parent->put(0, 0);
    my $N = 8;
    my $wins = race($N, sub { Data::HashMap::Shared::II->new($path, 100) },
                        sub { $_[0]->cas(0, 0, $_[1]) });
    is($wins, 1, "concurrent CAS: exactly 1 winner across $N workers");
    my $final = $parent->get(0);
    ok($final >= 1 && $final <= $N, "CAS winner stored a valid worker id ($final)");
    unlink $path;
}

# ttl 0 takes the read-locked cas path, ttl 60 the write-locked one
for my $ttl (0, 60) {
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100, 0, $ttl);
    $parent->put(0, 0);
    my ($N, $each) = (4, 2000);
    race($N, sub { Data::HashMap::Shared::II->new($path, 100, 0, $ttl) },
             sub { for (1 .. $each) { my $v; do { $v = $_[0]->get(0) } until $_[0]->cas(0, $v, $v + 1) } 1 });
    is($parent->get(0), $N * $each, "cas counting, ttl $ttl: no lost update");
    unlink $path;
}

{
    my $path = tmpfile();
    my $N = 6;
    my $inserts = race($N, sub { Data::HashMap::Shared::II->new($path, 100) },
                           sub { $_[0]->add(42, $_[1]) });
    is($inserts, 1, "concurrent add: exactly 1 insert across $N workers");
    unlink $path;
}

{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100);
    my $N = 20;
    race($N, sub { Data::HashMap::Shared::II->new($path, 100) },
             sub { $_[0]->incr(1) });
    is($parent->get(1), $N, "concurrent incr: parent sees $N");
    unlink $path;
}

{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::SS->new($path, 100);
    $parent->put("token", "secret");
    my $N = 5;
    my $wins = race($N, sub { Data::HashMap::Shared::SS->new($path, 100) },
                        sub { defined $_[0]->cas_take("token", "secret") });
    is($wins, 1, "concurrent cas_take: exactly 1 worker claimed the token");
    ok(!$parent->exists("token"), "cas_take: token removed");
    unlink $path;
}

done_testing;
