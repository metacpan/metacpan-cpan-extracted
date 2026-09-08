use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_fork') . '.shm' }

# Every worker opens its own handle, then waits on a pipe barrier so all of them
# reach the contested call together: a bare fork loop lets the first child
# finish before the last one exists, and nothing races.  Returns how many
# workers' calls returned true, after checking that none died on a signal.
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
    close $w;                                  # release every worker at once
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

# Concurrent CAS: many workers race to flip a value 0 -> 1. Exactly one wins.
{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100);
    $parent->put(0, 0);   # the contested cell
    my $N = 8;
    my $wins = race($N, sub { Data::HashMap::Shared::II->new($path, 100) },
                        sub { $_[0]->cas(0, 0, $_[1]) });
    is($wins, 1, "concurrent CAS: exactly 1 winner across $N workers");
    my $final = $parent->get(0);
    ok($final >= 1 && $final <= $N, "CAS winner stored a valid worker id ($final)");
    unlink $path;
}

# Concurrent add: only the first worker per key inserts; the others see add fail.
{
    my $path = tmpfile();
    my $N = 6;
    my $inserts = race($N, sub { Data::HashMap::Shared::II->new($path, 100) },
                           sub { $_[0]->add(42, $_[1]) });
    is($inserts, 1, "concurrent add: exactly 1 insert across $N workers");
    unlink $path;
}

# Concurrent incr: the sum visible to the parent equals N
{
    my $path = tmpfile();
    my $parent = Data::HashMap::Shared::II->new($path, 100);
    my $N = 20;
    race($N, sub { Data::HashMap::Shared::II->new($path, 100) },
             sub { $_[0]->incr(1) });
    is($parent->get(1), $N, "concurrent incr: parent sees $N");
    unlink $path;
}

# Concurrent cas_take: only one process gets the value
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
