#!/usr/bin/env perl
# Shared RGBA pixel buffer → GL texture upload
#
# Pattern: a compute/capture process writes pixel data into a shared U8 buffer,
# the render process uploads it to a GL texture each frame via as_scalar.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::U8;
use Data::Buffer::Shared::I64;

my $width = 64;
my $height = 64;
my $channels = 4;  # RGBA
my $npixels = $width * $height * $channels;

my $pixels = Data::Buffer::Shared::U8->new_anon($npixels);
my $ctl = Data::Buffer::Shared::I64->new_anon(2); # 0=frame, 1=quit
$ctl->create_eventfd;

my $pid = fork();
if ($pid == 0) {
    # === IMAGE PRODUCER (e.g. camera capture, procedural generation) ===
    for my $frame (0..19) {
        # generate a simple animated gradient
        $pixels->lock_wr;
        for my $y (0..$height-1) {
            for my $x (0..$width-1) {
                my $base = ($y * $width + $x) * 4;
                $pixels->set($base + 0, ($x + $frame * 4) & 0xFF);  # R
                $pixels->set($base + 1, ($y + $frame * 2) & 0xFF);  # G
                $pixels->set($base + 2, ($frame * 8) & 0xFF);        # B
                $pixels->set($base + 3, 255);                         # A
            }
        }
        $pixels->unlock_wr;
        $ctl->incr(0);
        $ctl->notify;
    }
    # faster: bulk write via set_raw
    my $raw = pack("C*", map { ($_ * 3) & 0xFF } 0..$npixels-1);
    $pixels->set_raw(0, $raw);
    $ctl->incr(0);
    $ctl->notify;

    $ctl->set(1, 1);
    $ctl->notify;
    _exit(0);
}

# === GL RENDERER (simulated) ===
my $ref = $pixels->as_scalar;
my $frames = 0;
my $t0 = time();

while (!$ctl->get(1)) {
    my $n = $ctl->wait_notify;
    unless (defined $n) { sleep 0.001; next }

    # --- With OpenGL::Modern ---
    # glBindTexture(GL_TEXTURE_2D, $tex_id);
    # glTexSubImage2D_c(GL_TEXTURE_2D, 0, 0, 0, $width, $height,
    #                   GL_RGBA, GL_UNSIGNED_BYTE, $pixels->ptr);
    #
    # Or via Perl string (copies once into GL driver):
    # glTexSubImage2D_s(GL_TEXTURE_2D, 0, 0, 0, $width, $height,
    #                   GL_RGBA, GL_UNSIGNED_BYTE, $$ref);

    $frames += $n;
}
waitpid($pid, 0);

my $elapsed = time() - $t0;
printf "texture: %dx%d RGBA (%d bytes)\n", $width, $height, $npixels;
printf "frames produced: %d\n", $ctl->get(0);
printf "frames consumed: %d\n", $frames;
printf "elapsed: %.3fs (%.0f fps)\n", $elapsed, $frames / ($elapsed || 1);

# verify final pixel data
my $px0 = join(',', map { $pixels->get($_) } 0..3);
printf "pixel (0,0) RGBA: %s\n", $px0;
