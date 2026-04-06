#!/usr/bin/env perl
# Image processing pipeline: capture → PDL filter → GL display
#
# Three-stage pipeline using shared U8 buffers:
#   Stage 1: capture/generate raw RGBA frames
#   Stage 2: PDL processes (blur, threshold, etc.)
#   Stage 3: GL renders the processed frame
#
# Each stage runs in a separate process, communicating via shared
# buffers + eventfd.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::U8;
use Data::Buffer::Shared::I64;

my $w = 16;
my $h = 16;
my $npx = $w * $h * 4;  # RGBA
my $nframes = 10;

# two frame buffers: raw → processed
my $raw_buf = Data::Buffer::Shared::U8->new_anon($npx);
my $proc_buf = Data::Buffer::Shared::U8->new_anon($npx);
my $ctl = Data::Buffer::Shared::I64->new_anon(4);
# ctl: 0=raw_ready, 1=proc_ready, 2=quit, 3=frames_done
$ctl->create_eventfd;

# --- Stage 1: capture ---
my $cap_pid = fork();
if ($cap_pid == 0) {
    for my $f (0..$nframes-1) {
        # generate a test pattern
        my @frame;
        for my $y (0..$h-1) {
            for my $x (0..$w-1) {
                push @frame,
                    ($x * 4 + $f) & 0xFF,     # R
                    ($y * 4 + $f * 2) & 0xFF,  # G
                    128,                         # B
                    255;                         # A
            }
        }
        $raw_buf->set_raw(0, pack("C*", @frame));
        $ctl->incr(0);
        $ctl->notify;

        # throttle to ~120 fps
        sleep 0.008;
    }
    _exit(0);
}

# --- Stage 2: process ---
my $proc_pid = fork();
if ($proc_pid == 0) {
    my $processed = 0;
    while ($processed < $nframes) {
        my $n = $ctl->wait_notify;
        unless (defined $n) { sleep 0.001; next }

        my $ready = $ctl->get(0);
        next if $ready <= $processed;

        # read raw frame
        my $raw = $raw_buf->get_raw(0, $npx);

        # --- With PDL ---
        # use PDL;
        # my $img = PDL->new_from_specification(byte, 4, $w, $h);
        # ${$img->get_dataref} = $raw;
        # $img->upd_data;
        #
        # # apply 3x3 box blur on each channel
        # my $kernel = ones(3,3) / 9;
        # $img = $img->conv2d($kernel);
        #
        # # threshold
        # $img = ($img > 128) * 255;
        #
        # $proc_buf->set_raw(0, ${$img->get_dataref});

        # Without PDL: simple brightness boost (saturating add)
        my @px = unpack("C*", $raw);
        for my $i (0..$#px) {
            next if ($i % 4) == 3;  # skip alpha
            $px[$i] = $px[$i] + 30 > 255 ? 255 : $px[$i] + 30;
        }
        $proc_buf->set_raw(0, pack("C*", @px));

        $ctl->incr(1);
        $ctl->notify;
        $processed++;
    }
    _exit(0);
}

# --- Stage 3: render (simulated) ---
my $ref = $proc_buf->as_scalar;
my $rendered = 0;
my $t0 = time();

while ($rendered < $nframes) {
    my $n = $ctl->wait_notify;
    unless (defined $n) { sleep 0.001; next }

    my $ready = $ctl->get(1);
    next if $ready <= $rendered;

    # --- With OpenGL::Modern ---
    # glTexSubImage2D_s(GL_TEXTURE_2D, 0, 0, 0, $w, $h,
    #                   GL_RGBA, GL_UNSIGNED_BYTE, $$ref);
    # render_fullscreen_quad();
    # glutSwapBuffers();

    $rendered = $ready;
}

waitpid($cap_pid, 0);
waitpid($proc_pid, 0);
my $elapsed = time() - $t0;

printf "pipeline: capture → process → render\n";
printf "resolution: %dx%d RGBA\n", $w, $h;
printf "frames: %d captured, %d processed, %d rendered\n",
    $ctl->get(0), $ctl->get(1), $rendered;
printf "elapsed: %.3fs (%.0f fps effective)\n", $elapsed, $rendered / ($elapsed || 1);

# verify processed pixel
my @px = unpack("C4", $proc_buf->get_raw(0, 4));
printf "processed pixel(0,0) RGBA: %s\n", join(',', @px);
