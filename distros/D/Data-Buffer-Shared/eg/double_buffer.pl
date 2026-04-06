#!/usr/bin/env perl
# Double-buffered rendering: swap between two shared buffers
#
# The producer writes to the back buffer while the consumer reads from
# the front buffer. An atomic swap index selects which is which.
# No tearing, no locking on the render path.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::I64;

my $buf_size = 1000;  # floats per buffer

# two frame buffers
my $buf0 = Data::Buffer::Shared::F32->new_anon($buf_size);
my $buf1 = Data::Buffer::Shared::F32->new_anon($buf_size);

# control: slot 0 = front buffer index (0 or 1), slot 1 = frame count, slot 2 = quit
my $ctl = Data::Buffer::Shared::I64->new_anon(3);
$ctl->create_eventfd;
$ctl->set(0, 0);  # buffer 0 is initially front

my $nframes = 100;

my $pid = fork();
if ($pid == 0) {
    # === PRODUCER: write to back buffer, then swap ===
    my @bufs = ($buf0, $buf1);
    for my $frame (1..$nframes) {
        # determine back buffer (opposite of front)
        my $front = $ctl->get(0);
        my $back_idx = 1 - $front;
        my $back = $bufs[$back_idx];

        # write frame data to back buffer
        $back->lock_wr;
        for my $i (0..$buf_size-1) {
            $back->set($i, sin($i * 0.01 + $frame * 0.1) * $frame);
        }
        $back->unlock_wr;

        # atomic swap: back becomes front
        $ctl->set(0, $back_idx);
        $ctl->incr(1);
        $ctl->notify;
    }
    $ctl->set(2, 1);
    $ctl->notify;
    _exit(0);
}

# === CONSUMER: always read from front buffer (no lock needed for GL upload) ===
my @bufs = ($buf0, $buf1);
my @refs = ($buf0->as_scalar, $buf1->as_scalar);
my $rendered = 0;
my $t0 = time();

while (!$ctl->get(2)) {
    my $n = $ctl->wait_notify;
    unless (defined $n) { sleep 0.001; next }

    my $front = $ctl->get(0);
    my $ref = $refs[$front];

    # --- With OpenGL::Modern ---
    # glBufferSubData_p(GL_ARRAY_BUFFER, 0, $$ref);
    # # No lock needed! Producer writes to the OTHER buffer.
    # # This read is always from a completed frame.

    $rendered += $n;
}
waitpid($pid, 0);

my $elapsed = time() - $t0;
printf "double buffer: %d floats/frame (%d bytes)\n", $buf_size, $buf_size * 4;
printf "frames produced: %d, consumed: %d\n", $ctl->get(1), $rendered;
printf "elapsed: %.3fs (%.0f fps)\n", $elapsed, $rendered / ($elapsed || 1);

# verify front buffer has data
my $front = $ctl->get(0);
my @sample = $bufs[$front]->slice(0, 5);
printf "front buffer[0..4]: %s\n",
    join(' ', map { sprintf("%.2f", $_) } @sample);
