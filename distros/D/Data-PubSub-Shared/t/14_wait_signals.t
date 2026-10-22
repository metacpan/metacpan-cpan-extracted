use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time sleep alarm ualarm);
use Data::PubSub::Shared;

sub finish_child {
    my ($pid) = @_;
    my $deadline = time + 3;
    while (time < $deadline) {
        return $? == 0 if waitpid($pid, WNOHANG) == $pid;
        sleep 0.01;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
    return 0;
}

for my $variant (qw(Int Int32 Int16 Str)) {
    for my $method (qw(poll_wait poll_wait_multi)) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $ok = eval {
                my $ps = "Data::PubSub::Shared::$variant"->new(undef, 16);
                my $sub = $ps->subscribe;
                for my $timeout (undef, 1) {
                    local $SIG{ALRM} = sub { die "wait interrupted\n" };
                    alarm 0.03;
                    eval {
                        $method eq 'poll_wait' ? $sub->poll_wait($timeout)
                            : $sub->poll_wait_multi(2, $timeout);
                    };
                    alarm 0;
                    die "signal not handled: $@" unless $@ =~ /wait interrupted/;
                    die "waiter leaked" if $ps->stats->{sub_waiters};
                }
                local $SIG{ALRM} = sub { $ps->publish(7) };
                alarm 0.03;
                my @got = $method eq 'poll_wait' ? $sub->poll_wait(1)
                    : $sub->poll_wait_multi(2, 1);
                alarm 0;
                die "signal handler publish not received" unless @got == 1 && $got[0] eq '7';
                die "waiter leaked" if $ps->stats->{sub_waiters};
                1;
            };
            warn $@ unless $ok;
            _exit($ok ? 0 : 1);
        }
        ok finish_child($pid), "$variant $method handles signals and releases its waiter";
    }
}

{
    my $ps = Data::PubSub::Shared::Str->new(undef, 16, 8);
    my $sub = $ps->subscribe;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $got = $sub->poll_wait;
        _exit(defined($got) && $got eq 'ok' ? 0 : 1);
    }
    my $deadline = time + 2;
    sleep 0.001 while !$ps->stats->{sub_waiters} && time < $deadline;
    my $waiting = $ps->stats->{sub_waiters};
    eval { $ps->publish_multi('ok', 'x' x 9) };
    like $@, qr/too long/, 'oversized batch still croaks';
    ok $waiting && finish_child($pid), 'published batch prefix wakes an already waiting subscriber';
    if (!$waiting) { kill 'KILL', $pid; waitpid($pid, 0) }
}

for my $method (qw(publish publish_multi clear)) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $ok = eval {
            my $ps = Data::PubSub::Shared::Str->new_memfd('mutex-signal', 16);
            open my $fh, '+<&', $ps->memfd or die "dup: $!";
            sysseek($fh, 72, 0) // die "seek: $!";
            syswrite($fh, pack('L', getppid() | 0x80000000)) == 4 or die "write: $!";
            local $SIG{ALRM} = sub { die "lock interrupted\n" };
            alarm 0.03;
            eval { $method eq 'clear' ? $ps->clear : $ps->$method('ok') };
            alarm 0;
            die "signal not handled: $@" unless $@ =~ /lock interrupted/;
            sysseek($fh, 76, 0) // die "seek: $!";
            sysread($fh, my $word, 4) == 4 or die "read: $!";
            die "mutex waiter leaked" if unpack('L', $word);
            sysseek($fh, 72, 0) // die "seek: $!";
            syswrite($fh, pack('L', 0)) == 4 or die "write: $!";
            $ps->publish('after');
            die "channel unusable" unless $ps->subscribe_all->poll eq 'after';
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    ok finish_child($pid), "Str $method handles signals while waiting for the mutex";
}

for my $method (qw(publish publish_notify)) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $ok = eval {
            my $ps = Data::PubSub::Shared::Str->new_memfd('mutex-payload', 16);
            open my $fh, '+<&', $ps->memfd or die "dup: $!";
            sysseek($fh, 72, 0) // die "seek: $!";
            syswrite($fh, pack('L', getppid() | 0x80000000)) == 4 or die "write: $!";
            my $msg = 'x' x 64;
            local $SIG{ALRM} = sub {
                $msg = 'changed' x 1024;
                sysseek($fh, 72, 0) // die "seek: $!";
                syswrite($fh, pack('L', 0)) == 4 or die "write: $!";
            };
            alarm 0.03;
            $ps->$method($msg);
            alarm 0;
            die "payload changed" unless $ps->subscribe_all->poll eq ('x' x 64);
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    ok finish_child($pid), "Str $method preserves its payload across a signal handler";
}

{
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $ok = eval {
            my $ps = Data::PubSub::Shared::Str->new_memfd('mutex-interruptions', 16);
            my $owner = fork // die "fork: $!";
            _exit(0) if !$owner;
            waitpid($owner, 0);
            open my $fh, '+<&', $ps->memfd or die "dup: $!";
            sysseek($fh, 72, 0) // die "seek: $!";
            syswrite($fh, pack('L', $owner | 0x80000000)) == 4 or die "write: $!";
            local $SIG{ALRM} = sub {};
            ualarm 20000, 20000;
            $ps->publish('recovered');
            ualarm 0;
            die "lock not recovered" unless $ps->stats->{recoveries} == 1;
            die "message lost" unless $ps->subscribe_all->poll eq 'recovered';
            sysseek($fh, 76, 0) // die "seek: $!";
            sysread($fh, my $word, 4) == 4 or die "read: $!";
            die "mutex waiter leaked" if unpack('L', $word);
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    ok finish_child($pid), 'periodic signals do not postpone dead mutex recovery';
}

done_testing;
