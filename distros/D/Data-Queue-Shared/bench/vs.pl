#!/usr/bin/env perl
# Benchmark: Data::Queue::Shared vs MCE::Queue, Forks::Queue, IPC::Msg,
# POSIX::RT::MQ, IPC::Transit
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX ();
use Fcntl;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $n = shift || 100_000;

my %has;
eval "use MCE::Queue";                                          $has{mce}     = !$@;
eval "use threads; use Thread::Queue";                          $has{tq}      = !$@;
eval "use Forks::Queue";                                        $has{fq}      = !$@;
eval "use POSIX::RT::MQ";                                       $has{rtmq}    = !$@;
eval "use IPC::Transit";                                        $has{transit}  = !$@;
BEGIN {
    eval "use IPC::Msg; use IPC::SysV qw(IPC_PRIVATE IPC_CREAT IPC_NOWAIT S_IRUSR S_IWUSR)";
    $has{sysvmq} = !$@;
}

sub rate_fmt {
    my ($label, $elapsed, $count) = @_;
    my $rate = $count / $elapsed;
    if ($rate >= 1_000_000) { return sprintf "%-40s %7.1fM/s", $label, $rate / 1_000_000 }
    if ($rate >= 1_000)     { return sprintf "%-40s %7.0fK/s", $label, $rate / 1_000 }
    return sprintf "%-40s %7.0f/s", $label, $rate;
}

sub bench {
    my ($label, $count, $code) = @_;
    my $t0 = time;
    $code->();
    print rate_fmt($label, time - $t0, $count), "\n";
}

my $cap = $n < 1048576 ? 1048576 : 2 * $n;
my $str50 = "x" x 50;

print "Queue benchmark: $n ops, single process\n";
print "=" x 55, "\n\n";

# ========================================================
print "--- INTEGER PUSH+POP (interleaved) ---\n\n";
# ========================================================

bench "Data::Queue::Shared::Int" => $n, sub {
    my $q = Data::Queue::Shared::Int->new(undef, $cap);
    for (1..$n) { $q->push($_); $q->pop }
};

if ($has{mce}) {
    bench "MCE::Queue" => $n, sub {
        my $q = MCE::Queue->new;
        for (1..$n) { $q->enqueue($_); $q->dequeue }
    };
}

if ($has{tq}) {
    bench "Thread::Queue" => $n, sub {
        my $q = Thread::Queue->new;
        for (1..$n) { $q->enqueue($_); $q->dequeue }
    };
}

if ($has{fq}) {
    bench "Forks::Queue (Shmem)" => $n, sub {
        my $q = Forks::Queue->new(impl => "Shmem", style => "fifo");
        for (1..$n) { $q->put($_); $q->get }
        $q->end;
    };
}

if ($has{sysvmq}) {
    bench "IPC::Msg (SysV)" => $n, sub {
        my $q = IPC::Msg->new(IPC_PRIVATE, IPC_CREAT | S_IRUSR | S_IWUSR) or die;
        my $buf;
        for (1..$n) { $q->snd(1, pack("l",$_)); $q->rcv($buf, 4, 1) }
        $q->remove;
    };
}

if ($has{rtmq}) {
    my $mqn = "/bench_int_$$";
    bench "POSIX::RT::MQ" => $n, sub {
        my $q = POSIX::RT::MQ->open($mqn, O_RDWR|O_CREAT, 0600,
            {mq_maxmsg => 1024, mq_msgsize => 64}) or die "mq_open: $!";
        for (1..$n) { $q->send(pack("l",$_)); $q->receive }
        $q->close;
        POSIX::RT::MQ->unlink($mqn);
    };
}

if ($has{transit}) {
    my $qname = "bench_int_$$";
    bench "IPC::Transit" => $n, sub {
        for (1..$n) {
            IPC::Transit::send(qname => $qname, message => {v => $_});
            IPC::Transit::receive(qname => $qname);
        }
    };
    eval { IPC::Transit::post_receive({qname => $qname}) };
}

# ========================================================
print "\n--- STRING PUSH+POP (~50B, interleaved) ---\n\n";
# ========================================================

bench "Data::Queue::Shared::Str" => $n, sub {
    my $q = Data::Queue::Shared::Str->new(undef, $cap);
    for (1..$n) { $q->push($str50); $q->pop }
};

if ($has{mce}) {
    bench "MCE::Queue" => $n, sub {
        my $q = MCE::Queue->new;
        for (1..$n) { $q->enqueue($str50); $q->dequeue }
    };
}

if ($has{fq}) {
    bench "Forks::Queue (Shmem)" => $n, sub {
        my $q = Forks::Queue->new(impl => "Shmem", style => "fifo");
        for (1..$n) { $q->put($str50); $q->get }
        $q->end;
    };
}

if ($has{sysvmq}) {
    bench "IPC::Msg (SysV)" => $n, sub {
        my $q = IPC::Msg->new(IPC_PRIVATE, IPC_CREAT | S_IRUSR | S_IWUSR) or die;
        my $buf;
        for (1..$n) { $q->snd(1, $str50); $q->rcv($buf, 256, 1) }
        $q->remove;
    };
}

if ($has{rtmq}) {
    my $mqn = "/bench_str_$$";
    bench "POSIX::RT::MQ" => $n, sub {
        my $q = POSIX::RT::MQ->open($mqn, O_RDWR|O_CREAT, 0600,
            {mq_maxmsg => 1024, mq_msgsize => 256}) or die "mq_open: $!";
        for (1..$n) { $q->send($str50); $q->receive }
        $q->close;
        POSIX::RT::MQ->unlink($mqn);
    };
}

# ========================================================
print "\n--- BATCH PUSH+POP (100/batch, integers) ---\n\n";
# ========================================================

my $batch = 100;
my $iters = int($n / $batch);

bench "Data::Queue::Shared::Int" => $n, sub {
    my $q = Data::Queue::Shared::Int->new(undef, $cap);
    my @vals = (1..$batch);
    for (1..$iters) { $q->push_multi(@vals); $q->pop_multi($batch) }
};

if ($has{mce}) {
    bench "MCE::Queue" => $n, sub {
        my $q = MCE::Queue->new;
        my @vals = (1..$batch);
        for (1..$iters) { $q->enqueue(@vals); $q->dequeue($batch) }
    };
}

# ========================================================
print "\n--- CROSS-PROCESS: 1 producer + 1 consumer, $n integers ---\n\n";
# ========================================================

{
    my $q = Data::Queue::Shared::Int->new(undef, $cap);
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) { $q->push($_) for 1..$n; POSIX::_exit(0) }
    my $got = 0;
    while ($got < $n) { $got++ if defined $q->pop }
    waitpid($pid, 0);
    print rate_fmt("Data::Queue::Shared::Int", time - $t0, $n), "\n";
}

if ($has{mce}) {
    require MCE;
    my $q = MCE::Queue->new;
    my $t0 = time;
    MCE->new(max_workers => 1, user_func => sub { $q->enqueue($_) for 1..$n })->run;
    my $got = 0;
    $got++ while defined $q->dequeue_nb;
    print rate_fmt("MCE::Queue (produce+drain)", time - $t0, $n), "\n";
}

if ($has{fq}) {
    my $q = Forks::Queue->new(impl => "Shmem", style => "fifo");
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) { $q->put($_) for 1..$n; $q->end; POSIX::_exit(0) }
    my $got = 0;
    while (1) { my $v = $q->get; last unless defined $v; $got++ }
    waitpid($pid, 0);
    print rate_fmt("Forks::Queue (Shmem)", time - $t0, $n), "\n";
}

if ($has{rtmq}) {
    my $mqn = "/bench_xp_$$";
    my $q = POSIX::RT::MQ->open($mqn, O_RDWR|O_CREAT, 0600,
        {mq_maxmsg => 1024, mq_msgsize => 64}) or die "mq_open: $!";
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) {
        my $cq = POSIX::RT::MQ->open($mqn, O_WRONLY) or die;
        $cq->send(pack("l",$_)) for 1..$n;
        POSIX::_exit(0);
    }
    my $got = 0;
    $got++ while $got < $n && defined $q->receive;
    waitpid($pid, 0);
    $q->close;
    POSIX::RT::MQ->unlink($mqn);
    print rate_fmt("POSIX::RT::MQ", time - $t0, $n), "\n";
}

if ($has{sysvmq}) {
    my $q = IPC::Msg->new(IPC_PRIVATE, IPC_CREAT | S_IRUSR | S_IWUSR) or die;
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) { $q->snd(1, pack("l",$_)) for 1..$n; POSIX::_exit(0) }
    my ($buf, $got) = ('', 0);
    while ($got < $n) {
        if ($q->rcv($buf, 4, 1, IPC_NOWAIT)) { $got++ }
    }
    waitpid($pid, 0);
    $q->remove;
    print rate_fmt("IPC::Msg (SysV)", time - $t0, $n), "\n";
}

# ========================================================
print "\n--- CROSS-PROCESS: 1 producer + 1 consumer, $n strings ~50B ---\n\n";
# ========================================================

{
    my $q = Data::Queue::Shared::Str->new(undef, $cap);
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) { $q->push($str50) for 1..$n; POSIX::_exit(0) }
    my $got = 0;
    while ($got < $n) { $got++ if defined $q->pop }
    waitpid($pid, 0);
    print rate_fmt("Data::Queue::Shared::Str", time - $t0, $n), "\n";
}

if ($has{mce}) {
    my $q = MCE::Queue->new;
    my $t0 = time;
    MCE->new(max_workers => 1, user_func => sub { $q->enqueue($str50) for 1..$n })->run;
    my $got = 0;
    $got++ while defined $q->dequeue_nb;
    print rate_fmt("MCE::Queue (produce+drain)", time - $t0, $n), "\n";
}

if ($has{fq}) {
    my $q = Forks::Queue->new(impl => "Shmem", style => "fifo");
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) { $q->put($str50) for 1..$n; $q->end; POSIX::_exit(0) }
    my $got = 0;
    while (1) { my $v = $q->get; last unless defined $v; $got++ }
    waitpid($pid, 0);
    print rate_fmt("Forks::Queue (Shmem)", time - $t0, $n), "\n";
}

if ($has{rtmq}) {
    my $mqn = "/bench_xps_$$";
    my $q = POSIX::RT::MQ->open($mqn, O_RDWR|O_CREAT, 0600,
        {mq_maxmsg => 1024, mq_msgsize => 256}) or die "mq_open: $!";
    my $t0 = time;
    my $pid = fork // die;
    if ($pid == 0) {
        my $cq = POSIX::RT::MQ->open($mqn, O_WRONLY) or die;
        $cq->send($str50) for 1..$n;
        POSIX::_exit(0);
    }
    my $got = 0;
    $got++ while $got < $n && defined $q->receive;
    waitpid($pid, 0);
    $q->close;
    POSIX::RT::MQ->unlink($mqn);
    print rate_fmt("POSIX::RT::MQ", time - $t0, $n), "\n";
}
