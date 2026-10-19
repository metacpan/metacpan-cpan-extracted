use Test2::V0;
use Test2::Util qw/CAN_REALLY_FORK/;
use Atomic::Pipe;

# The writer runs in a forked child. Where fork is emulated with threads
# (MSWin32) Test2 refuses it; the thread-based tests cover the reader there.
skip_all "This test needs a real fork()" unless CAN_REALLY_FORK;
use Time::HiRes qw/time/;
use POSIX ();

# Regression guard against quadratic reads coming back. Reading 8x the data
# must take well under 64x the time (what quadratic behavior gives); linear
# reading gives about 8x. The bound is loose so machine noise cannot trip it.
#
# Timing tests can flake on heavily loaded smokers, so skip there unless
# extended testing was asked for.
skip_all 'timing test; set EXTENDED_TESTING=1 to run under AUTOMATED_TESTING'
    if $ENV{AUTOMATED_TESTING} && !$ENV{EXTENDED_TESTING};

my $SMALL = 2 * 1024 * 1024;
my $LARGE = 16 * 1024 * 1024;
my $BOUND = 32;    # 8x the data; quadratic would be ~64x

my %CASES = (
    # One huge multi-part message: reassembly must not rebuild it per part.
    reassembly => {
        mixed => 0,
        write => sub { my ($w, $n) = @_; $w->write_message('r' x $n) },
    },
    # A stream of ~1 KB messages in mixed mode: the original bug.
    mixed_messages => {
        mixed => 1,
        write => sub { my ($w, $n) = @_; my $m = 'm' x 1000; $w->write_message($m) for 1 .. $n / 1000 },
    },
    # Plain line output in mixed mode (child STDOUT/STDERR).
    mixed_lines => {
        mixed => 1,
        write => sub {
            my ($w, $n) = @_;
            my $chunk = (('l' x 99) . "\n") x 1000;
            for (1 .. $n / length($chunk)) {
                my $off = 0;
                $off += syswrite($w->wh, $chunk, length($chunk) - $off, $off) while $off < length $chunk;
            }
        },
    },
);

sub time_read {
    my ($case, $bytes) = @_;
    my ($r, $w) = Atomic::Pipe->pair($case->{mixed} ? (mixed_data_mode => 1) : ());

    my $start = time;
    my $pid   = fork // die "fork: $!";
    unless ($pid) {
        $r->close;
        $case->{write}->($w, $bytes);
        $w->close;
        POSIX::_exit(0);
    }
    $w->close;

    if ($case->{mixed}) {
        while (1) {
            my %m = $r->get_line_burst_or_data;
            last if !%m && $r->eof;
        }
    }
    else {
        1 while defined $r->read_message;
    }
    waitpid($pid, 0);
    return time - $start;
}

for my $name (sort keys %CASES) {
    my $case = $CASES{$name};

    local $SIG{ALRM} = sub { die "timed out: reading is far from linear\n" };
    alarm 120;
    my ($small, $large) = (9**9, 9**9);
    for (1 .. 3) {
        my $s = time_read($case, $SMALL);
        my $l = time_read($case, $LARGE);
        $small = $s if $s < $small;
        $large = $l if $l < $large;
    }
    alarm 0;

    my $ratio = $large / ($small || 1e-6);
    ok($ratio < $BOUND, sprintf("%s: 8x the data took %.1fx the time (%.3fs vs %.3fs)", $name, $ratio, $large, $small));
}

done_testing;
