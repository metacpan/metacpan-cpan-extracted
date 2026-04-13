#!/usr/bin/env perl
# OpenGL particle system with shared pool
#
# Demonstrates the pool's unique value vs Buffer: particles are dynamically
# spawned (alloc) and despawned (free), not just indexed.
#
# Architecture:
#   - Pool stores per-particle state: x, y, vx, vy, r, g, b, life (8 floats = 64 bytes)
#   - Spawner process: periodically allocs new particles at emitter position
#   - Physics process: updates all living particles (gravity, drag, aging)
#   - Renderer (main): reads positions via data_ptr, uploads to VBO
#
# The GL code is commented but structurally accurate for OpenGL::Modern.
# Run without GL to see the simulation in text.
#
# Usage: perl opengl_particles.pl [max_particles]

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Pool::Shared;
$| = 1;

my $MAX = shift || 200;
my $DT  = 1.0 / 60;

# 8 doubles per particle: x y vx vy r g b life
my $SLOT_SIZE = 8 * 8;  # 64 bytes
my $pool = Data::Pool::Shared->new(undef, $MAX, $SLOT_SIZE);

sub pack_particle { pack('d<8', @_) }
sub unpack_particle { unpack('d<8', $_[0]->get($_[1])) }

printf "particle pool: max=%d, slot=%d bytes, data_ptr=0x%x\n\n",
    $MAX, $SLOT_SIZE, $pool->data_ptr;

# ── Spawner process ──────────────────────────────────────────────
# Emits bursts of particles from a moving emitter

my $spawner_pid = fork // die "fork: $!";
if ($spawner_pid == 0) {
    my $t = 0;
    for my $frame (1 .. 120) {
        $t += $DT;
        # emitter orbits the center
        my $ex = 400 + 150 * cos($t * 2);
        my $ey = 300 + 150 * sin($t * 3);

        # spawn a burst of 3-5 particles
        my $burst = 3 + int(rand(3));
        for (1 .. $burst) {
            my $s = $pool->try_alloc;
            next unless defined $s;
            my $angle = rand(6.28);
            my $speed = 30 + rand(80);
            $pool->set($s, pack_particle(
                $ex, $ey,                           # position
                cos($angle) * $speed,               # vx
                sin($angle) * $speed - 40,          # vy (bias upward)
                0.5 + rand(0.5),                    # r
                0.2 + rand(0.3),                    # g
                0.8 + rand(0.2),                    # b
                1.0 + rand(1.0),                    # life (seconds)
            ));
        }
        sleep($DT);
    }
    _exit(0);
}

# ── Physics process ──────────────────────────────────────────────
# Gravity, drag, aging — frees dead particles

my $physics_pid = fork // die "fork: $!";
if ($physics_pid == 0) {
    my $gravity = 120;
    my $drag    = 0.98;

    for my $frame (1 .. 120) {
        my $alive = $pool->allocated_slots;
        for my $s (@$alive) {
            my ($x, $y, $vx, $vy, $r, $g, $b, $life) = unpack_particle($pool, $s);

            # age
            $life -= $DT;
            if ($life <= 0) {
                $pool->free($s);
                next;
            }

            # physics
            $vy += $gravity * $DT;  # gravity
            $vx *= $drag;           # drag
            $vy *= $drag;
            $x  += $vx * $DT;
            $y  += $vy * $DT;

            # fade color as life decreases
            my $fade = $life / 2.0;
            $fade = 1.0 if $fade > 1.0;

            $pool->set($s, pack_particle(
                $x, $y, $vx, $vy,
                $r * $fade, $g * $fade, $b * $fade,
                $life,
            ));
        }
        sleep($DT);
    }
    _exit(0);
}

# ── Renderer (main process) ─────────────────────────────────────
#
# Real OpenGL code would be:
#
#   # Setup (once):
#   my ($vao) = glGenVertexArrays_p(1);
#   my ($vbo) = glGenBuffers_p(1);
#   glBindVertexArray($vao);
#   glBindBuffer(GL_ARRAY_BUFFER, $vbo);
#   glBufferData_c(GL_ARRAY_BUFFER, $MAX * $SLOT_SIZE, 0, GL_STREAM_DRAW);
#   # attrib 0: position (2 doubles at offset 0)
#   glVertexAttribLPointer(0, 2, GL_DOUBLE, $SLOT_SIZE, 0);
#   glEnableVertexAttribArray(0);
#   # attrib 1: color (3 doubles at offset 32)
#   glVertexAttribLPointer(1, 3, GL_DOUBLE, $SLOT_SIZE, 32);
#   glEnableVertexAttribArray(1);
#
#   # Per frame:
#   my $alive = $pool->allocated_slots;
#   my $n = scalar @$alive;
#   # Upload only alive particles:
#   for my $i (0 .. $n - 1) {
#       glBufferSubData_c(GL_ARRAY_BUFFER, $i * $SLOT_SIZE, $SLOT_SIZE,
#                          $pool->ptr($alive->[$i]));
#   }
#   # Or bulk upload entire data region (includes dead slots):
#   glBufferSubData_c(GL_ARRAY_BUFFER, 0, $pool->used * $SLOT_SIZE,
#                      $pool->data_ptr);
#   glDrawArrays(GL_POINTS, 0, $n);

my $t0 = time;
my $frames = 0;
for (1 .. 20) {
    sleep(0.1);
    $frames++;
    my $alive = $pool->allocated_slots;
    my $n = scalar @$alive;

    # sample a few particles for text display
    if ($n > 0) {
        my $sample = $alive->[int($n / 2)];
        my ($x, $y, $vx, $vy, $r, $g, $b, $life) = unpack_particle($pool, $sample);
        printf "  frame %2d: %3d alive | sample pos=(%.0f,%.0f) vel=(%.0f,%.0f) "
             . "rgb=(%.2f,%.2f,%.2f) life=%.1f\n",
            $frames, $n, $x, $y, $vx, $vy, $r, $g, $b, $life;
    } else {
        printf "  frame %2d: %3d alive\n", $frames, $n;
    }
}

waitpid($spawner_pid, 0);
waitpid($physics_pid, 0);

my $dt = time - $t0;
my $st = $pool->stats;
printf "\n%d frames in %.1fs (%.0f fps)\n", $frames, $dt, $frames / $dt;
printf "stats: allocs=%d frees=%d (spawned and despawned)\n",
    $st->{allocs}, $st->{frees};
printf "final: %d particles still alive\n", $pool->used;
$pool->reset;
