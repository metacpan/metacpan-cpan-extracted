use Test2::V0;
use Test2::Util qw/CAN_REALLY_FORK/;
use Atomic::Pipe;

# The writer runs in a forked child. Where fork is emulated with threads
# (MSWin32) Test2 refuses it; the thread-based tests cover the reader there.
skip_all "This test needs a real fork()" unless CAN_REALLY_FORK;

# Whole parts already in the buffer take a one-step fast path; anything split
# across reads takes the step-by-step path. Varying read_size makes a single
# message cross between the two, and two writers interleave their parts.

my $part = Atomic::Pipe::PIPE_BUF() - 16;

my @MSGS = (
    'small',
    'x' x ($part * 3 + 7),          # multi-part
    'y' x $part,                     # one full part without mixed mode
    'z' x ($part + 1),               # one byte into a second part
    join('' => map { chr($_ % 256) } 1 .. 10_000),
);

for my $mixed (0, 1) {
    for my $rs (1, 5, 17, 100, 4096, 65536) {
        my ($r, $w) = Atomic::Pipe->pair($mixed ? (mixed_data_mode => 1) : ());
        $r->read_size($rs);

        my @pids;
        for my $writer (1, 2) {
            my $pid = fork // die "fork: $!";
            unless ($pid) {
                $r->close;
                $w->write_message("$writer:$_") for @MSGS;
                $w->close;
                exit 0;
            }
            push @pids => $pid;
        }
        $w->close;

        my %got;
        if ($mixed) {
            while (1) {
                my %m = $r->get_line_burst_or_data;
                last if !%m && $r->eof;
                next unless defined $m{message};
                my ($writer, $msg) = split /:/, $m{message}, 2;
                push @{$got{$writer}} => $msg;
            }
        }
        else {
            while (defined(my $m = $r->read_message)) {
                my ($writer, $msg) = split /:/, $m, 2;
                push @{$got{$writer}} => $msg;
            }
        }
        waitpid($_, 0) for @pids;

        is(\%got, {1 => \@MSGS, 2 => \@MSGS}, ($mixed ? 'mixed' : 'read_message') . ", read_size $rs: both writers' messages intact and in order");
    }
}

subtest debug_mode_reports_parts => sub {
    my ($r, $w) = Atomic::Pipe->pair;
    $w->write_message('d' x ($part * 2 + 1));
    $w->close;
    my $out = $r->read_message(debug => 1);
    is($out->{parts}, [2, 1, 0], 'debug lists every part id');
    is(length($out->{message}), $part * 2 + 1, 'debug message intact');
};

subtest partial_state_visible => sub {
    # Callers such as IPC::Manager inspect {state}{buffers} and {parts} to drop
    # half-received messages from writers that died.
    my ($r, $w) = Atomic::Pipe->pair;
    $w->write_message('p' x ($part * 2 + 1));
    $w->close;

    my ($id) = $r->_extract_message(one_part_only => 1);
    is($id, 2, 'took the first part only');
    my $tag = "$$:0";
    ok(exists $r->{state}->{buffers}->{$tag}, 'partial message buffered under pid:tid');
    is($r->{state}->{parts}->{$tag}, [2], 'part ids tracked');

    is(length($r->read_message), $part * 2 + 1, 'rest of the message completes it');
    ok(!exists $r->{state}->{buffers}->{$tag}, 'state cleared once complete');
};

done_testing;
