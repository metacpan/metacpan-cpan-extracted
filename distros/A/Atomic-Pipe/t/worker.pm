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

1;
