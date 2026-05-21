use Test2::V0;
use Test2::IPC;

use Test2::Util qw/CAN_REALLY_FORK CAN_THREAD/;

skip_all "This test requires either forking or threads"
    unless CAN_REALLY_FORK || CAN_THREAD;

if (CAN_REALLY_FORK) {
    diag "Using fork()...\n";

    my @pids;

    *cleanup = sub() { waitpid($_, 0) for @pids; @pids = () };
    *worker  = sub(&) {
        my ($code) = @_;
        my $pid = fork // die "Could not fork: $!";
        return push @pids => $pid if $pid;

        my $ok  = eval { $code->(); 1 };
        my $err = $@;
        exit(0) if $ok;
        warn $err;
        exit 255;
    }
}
else {
    diag "Using threads...\n";
    require threads;

    my @threads;
    *cleanup = sub() { $_->join for @threads; @threads = () };
    *worker  = sub(&) {
        my ($code) = @_;

        # Prevent weird deadlock on win32
        if ($^O eq 'MSWin32') {
            my $inner = $code;
            $code = sub { sleep 2; $inner->() };
        }

        push @threads => threads->create($code);
    };
}

sub note_sleep {
    my ($end) = @_;
    for (1 .. 10) {
        print "# " . ($end - $_ + 1) . "\n";
        sleep 1;
    }
}

sub make_sync {
    pipe(my $tw_r, my $tw_w) or die "pipe: $!";
    pipe(my $fw_r, my $fw_w) or die "pipe: $!";
    my $old = select $tw_w; $| = 1; select $fw_w; $| = 1; select $old;
    return {
        to_worker_r   => $tw_r, to_worker_w   => $tw_w,
        from_worker_r => $fw_r, from_worker_w => $fw_w,
    };
}

sub sync_signal {
    my ($fh, $byte) = @_;
    $byte //= "X";
    my $n = syswrite($fh, $byte);
    die "sync_signal: $!" unless defined $n;
    die "sync_signal: short write ($n of " . length($byte) . ")" unless $n == length($byte);
}

sub sync_wait {
    my ($fh) = @_;
    my $buf = '';
    my $n = sysread($fh, $buf, 1);
    die "sync_wait: $!" unless defined $n;
    die "sync_wait: EOF before signal" unless $n;
    return $buf;
}

sub can_read_now {
    my ($fh) = @_;
    my $rin = '';
    vec($rin, fileno($fh), 1) = 1;
    my $n = select(my $rout = $rin, undef, undef, 0);
    return $n && $n > 0;
}

sub can_write_now {
    my ($fh) = @_;
    my $win = '';
    vec($win, fileno($fh), 1) = 1;
    my $n = select(undef, my $wout = $win, undef, 0);
    return $n && $n > 0;
}

1;
