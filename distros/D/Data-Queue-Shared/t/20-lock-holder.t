use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(O_RDWR);
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time sleep);
use Data::Queue::Shared::Str;

plan skip_all => 'needs /proc' unless -r "/proc/$$/stat" && -e '/proc/self/ns/pid';

# Plants a holder in QueueHeader.mutex (offset 192), as a process killed inside the lock leaves it.
my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/q.shm";
my $q = Data::Queue::Shared::Str->new($path, 64, 1 << 16);

sub hold_as {
    my ($pid) = @_;
    sysopen my $fh, $path, O_RDWR or die "$path: $!";
    sysseek $fh, 192, 0 or die $!;
    syswrite($fh, pack('L', $pid ? 0x80000000 | $pid : 0)) == 4 or die $!;
}

sub timed_push {
    my $t0 = time;
    my $ok = $q->push(shift);
    return ($ok, time - $t0);
}

{
    my $pid = fork // die "fork: $!";
    _exit(0) unless $pid;
    waitpid $pid, 0;
    hold_as($pid);
    my ($ok, $took) = timed_push('dead');
    ok $ok, 'push succeeds after its lock holder died';
    cmp_ok $took, '<', 1, '  within a second';
}

{
    my $pid = fork // die "fork: $!";
    _exit(0) unless $pid;
    my $state = '';
    for (1 .. 500) {
        open my $st, '<', "/proc/$pid/stat" or last;
        ($state) = <$st> =~ /\) (\S)/;
        last if $state eq 'Z';
        sleep 0.01;
    }
    is $state, 'Z', 'holder is an unreaped zombie';
    hold_as($pid);
    my ($ok, $took) = timed_push('zombie');
    ok $ok, 'push succeeds while the dead holder is still unreaped';
    cmp_ok $took, '<', 1, '  within a second';
    waitpid $pid, 0;
}

{
    my $holder = fork // die "fork: $!";
    unless ($holder) { sleep 60; _exit(0) }
    hold_as($holder);
    pipe my $r, my $w or die $!;
    my $pusher = fork // die "fork: $!";
    unless ($pusher) {
        close $r;
        my $ok = $q->push('live');
        syswrite $w, $ok ? "ok\n" : "fail\n";
        _exit(0);
    }
    close $w;
    sleep 0.5;
    is waitpid($pusher, WNOHANG), 0, 'a live holder keeps the lock';
    kill KILL => $holder;
    waitpid $holder, 0;
    my $killed = time;
    my $line = <$r>;
    my $took = time - $killed;
    is $line, "ok\n", 'the blocked push completes once the holder dies';
    cmp_ok $took, '<', 1.2, '  soon after its death';
    waitpid $pusher, 0;
}

is $q->stats->{recoveries}, 3, 'each dead holder counted once';
is_deeply [ $q->drain ], [qw(dead zombie live)], 'no message lost or duplicated';

done_testing;
