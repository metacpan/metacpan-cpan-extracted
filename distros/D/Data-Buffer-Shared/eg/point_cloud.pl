#!/usr/bin/env perl
# Shared point cloud buffer for real-time 3D rendering
#
# Each point: x(f32) y(f32) z(f32) r(u8) g(u8) b(u8) a(u8) = 16 bytes
# Packed as F32 with 4 floats per point (xyz + packed rgba).
# A sensor/simulation process streams points, GL renders them.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::I64;

my $max_points = 10000;
my $floats_per_point = 4;  # x, y, z, rgba_packed

my $cloud = Data::Buffer::Shared::F32->new_anon($max_points * $floats_per_point);
my $ctl = Data::Buffer::Shared::I64->new_anon(2); # 0=num_points, 1=quit
$ctl->create_eventfd;

sub pack_rgba {
    my ($r, $g, $b, $a) = @_;
    # pack 4 bytes into a float via bit reinterpretation
    unpack("f", pack("CCCC", $r, $g, $b, $a));
}

my $pid = fork();
if ($pid == 0) {
    # === POINT CLOUD PRODUCER (e.g. LiDAR, depth camera, simulation) ===
    srand(42);
    for my $frame (0..19) {
        my $npts = 1000 + int(rand(2000));
        my @data;
        for my $i (0..$npts-1) {
            # generate points on a noisy sphere
            my $theta = rand(3.14159 * 2);
            my $phi = rand(3.14159);
            my $r = 10.0 + rand(0.5);
            push @data,
                $r * sin($phi) * cos($theta),  # x
                $r * sin($phi) * sin($theta),  # y
                $r * cos($phi),                 # z
                pack_rgba(
                    int(sin($phi) * 255),              # R: height-based
                    int(cos($theta) * 127 + 128),      # G: angle-based
                    200,                                # B: constant
                    255,                                # A: opaque
                );
        }
        # bulk write all points
        my $packed = pack("f<*", @data);
        $cloud->set_raw(0, $packed);
        $ctl->set(0, $npts);
        $ctl->notify;
        sleep 0.05;  # 20 fps update
    }
    $ctl->set(1, 1);
    $ctl->notify;
    _exit(0);
}

# === GL POINT CLOUD RENDERER (simulated) ===
my $ref = $cloud->as_scalar;
my $frames = 0;
my $t0 = time();

while (!$ctl->get(1)) {
    my $n = $ctl->wait_notify;
    unless (defined $n) { sleep 0.001; next }

    my $npts = $ctl->get(0);

    # --- With OpenGL::Modern ---
    # glBindBuffer(GL_ARRAY_BUFFER, $cloud_vbo);
    # glBufferSubData_p(GL_ARRAY_BUFFER, 0,
    #                   substr($$ref, 0, $npts * 16));
    #
    # # vertex layout: stride=16
    # # location=0: vec3 position, offset=0
    # # location=1: vec4 color (unpack RGBA in shader), offset=12
    # glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 16, 0);
    # glVertexAttribPointer_c(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, 16, 12);
    # glDrawArrays(GL_POINTS, 0, $npts);

    $frames++;
}
waitpid($pid, 0);

my $elapsed = time() - $t0;
my $npts = $ctl->get(0);
printf "point cloud: up to %d points (%d bytes/point)\n",
    $max_points, $floats_per_point * 4;
printf "last frame: %d points\n", $npts;
printf "render frames: %d (%.0f fps)\n", $frames, $frames / ($elapsed || 1);

# verify a point
my @p = unpack("f<3", $cloud->get_raw(0, 12));
printf "point 0: (%.2f, %.2f, %.2f)\n", @p;
