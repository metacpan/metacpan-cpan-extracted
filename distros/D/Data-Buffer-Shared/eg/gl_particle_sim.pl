#!/usr/bin/env perl
# Shared-memory particle simulation: compute + render in separate processes
#
# This demonstrates the full pipeline:
#   1. F32 buffer holds particle positions (x,y per particle)
#   2. Compute process updates positions each frame
#   3. Render process uploads to GL VBO via as_scalar (zero-copy)
#   4. eventfd synchronizes frames
#
# Without actual GL, this simulates the pattern and prints stats.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::I64;

my $nparticles = 1000;
my $nframes = 100;

# positions: x,y pairs → 2000 floats
my $pos = Data::Buffer::Shared::F32->new_anon($nparticles * 2);
# control: slot 0 = frame counter, slot 1 = quit flag
my $ctl = Data::Buffer::Shared::I64->new_anon(2);
$ctl->create_eventfd;

# initialize positions in a circle
for my $i (0..$nparticles-1) {
    my $angle = $i * 2.0 * 3.14159 / $nparticles;
    $pos->set($i * 2,     cos($angle) * 100.0);  # x
    $pos->set($i * 2 + 1, sin($angle) * 100.0);  # y
}

my $pid = fork();
if ($pid == 0) {
    # === COMPUTE PROCESS ===
    my $dt = 0.016;  # ~60fps
    for my $frame (1..$nframes) {
        # update all particles: simple rotation
        $pos->lock_wr;
        for my $i (0..$nparticles-1) {
            my $x = $pos->get($i * 2);
            my $y = $pos->get($i * 2 + 1);
            # rotate by dt radians
            my $nx = $x * cos($dt) - $y * sin($dt);
            my $ny = $x * sin($dt) + $y * cos($dt);
            $pos->set($i * 2,     $nx);
            $pos->set($i * 2 + 1, $ny);
        }
        $pos->unlock_wr;

        $ctl->incr(0);  # frame counter
        $ctl->notify;   # signal render
    }
    $ctl->set(1, 1);  # quit flag
    $ctl->notify;
    _exit(0);
}

# === RENDER PROCESS (simulated) ===
my $ref = $pos->as_scalar;
my $frames_rendered = 0;
my $t0 = time();

while (!$ctl->get(1)) {
    my $n = $ctl->wait_notify;
    unless (defined $n) {
        sleep 0.001;
        next;
    }

    # In real GL: glBufferSubData(GL_ARRAY_BUFFER, 0, length($$ref), $$ref)
    # The $$ref dereference gives the live mmap data — zero copy to GL driver.
    my $data_size = length($$ref);
    $frames_rendered += $n;  # eventfd accumulates multiple notifies
}

waitpid($pid, 0);
my $elapsed = time() - $t0;

printf "particles: %d\n", $nparticles;
printf "frames computed: %d\n", $ctl->get(0);
printf "frames rendered: %d\n", $frames_rendered;
printf "elapsed: %.3fs (%.0f fps)\n", $elapsed, $frames_rendered / $elapsed;
printf "buffer size: %d bytes (zero-copy to GL)\n", $nparticles * 2 * 4;
printf "first particle final pos: (%.2f, %.2f)\n", $pos->get(0), $pos->get(1);
