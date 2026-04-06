#!/usr/bin/env perl
# Shared buffer as GL Shader Storage Buffer Object (SSBO)
#
# SSBOs are read-write from compute/fragment shaders, up to ~128MB.
# A shared mmap buffer serves as the CPU-side staging area:
#   - Upload: set values in shared buffer → glBufferSubData_c
#   - Readback: glGetBufferSubData_c → read from shared buffer
#   - Zero-copy via ptr(): pass raw pointer directly to GL _c functions
#
# Pattern: compute shader writes particle positions into SSBO,
# CPU reads them back via shared buffer for collision detection
# or cross-process visibility.
#
# Requires: OpenGL::Modern, OpenGL::GLUT (for GL context)
use strict;
use warnings;

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::I64;

# 1000 particles, 4 floats each (x, y, z, w)
my $nparticles = 1000;
my $floats = $nparticles * 4;
my $buf = Data::Buffer::Shared::F32->new_anon($floats);

# initialize particle positions
for my $i (0..$nparticles-1) {
    my $angle = $i * 6.28318 / $nparticles;
    $buf->set($i * 4 + 0, cos($angle) * 10.0);  # x
    $buf->set($i * 4 + 1, sin($angle) * 10.0);  # y
    $buf->set($i * 4 + 2, 0.0);                   # z
    $buf->set($i * 4 + 3, 1.0);                   # w (mass)
}

my $ptr = $buf->ptr;
my $byte_size = $floats * 4;
my $ref = $buf->as_scalar;

printf "SSBO: %d particles, %d floats, %d bytes\n", $nparticles, $floats, $byte_size;
printf "ptr: 0x%x\n", $ptr;

# --- With OpenGL::Modern ---
# use OpenGL::Modern qw(:all);
# use OpenGL::Modern::Helpers qw(glGenBuffers_p);
#
# # Create SSBO
# my $ssbo = glGenBuffers_p(1);
# glBindBuffer(GL_SHADER_STORAGE_BUFFER, $ssbo);
#
# # Upload from shared buffer (zero-copy via ptr)
# glBufferData_c(GL_SHADER_STORAGE_BUFFER, $byte_size, $ptr, GL_DYNAMIC_COPY);
#
# # Bind to shader binding point 0
# # layout(std430, binding = 0) buffer ParticleBuffer {
# #     vec4 particles[];
# # };
# glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, $ssbo);
#
# # --- Dispatch compute shader ---
# # glUseProgram($compute_program);
# # glDispatchCompute(int($nparticles / 256) + 1, 1, 1);
# # glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
#
# # --- Readback into shared buffer ---
# glBindBuffer(GL_SHADER_STORAGE_BUFFER, $ssbo);
# glGetBufferSubData_c(GL_SHADER_STORAGE_BUFFER, 0, $byte_size, $ptr);
# # Now $buf->get($i) reflects GPU-computed values
#
# # --- Alternative: map buffer for zero-copy GPU→CPU ---
# # my $mapped = glMapBufferRange_c(GL_SHADER_STORAGE_BUFFER, 0, $byte_size,
# #                                  GL_MAP_READ_BIT);
# # # $mapped is a raw pointer — copy into shared buffer:
# # use Devel::Peek;  # or memcpy via Inline::C
# # $buf->set_raw(0, ...);  # would need pointer-to-string conversion
# # glUnmapBuffer(GL_SHADER_STORAGE_BUFFER);
#
# # --- Multiprocess pattern ---
# # Process A (physics compute shader):
# #   dispatch compute → readback into shared buffer → notify
# # Process B (collision detection, pure CPU):
# #   wait_notify → read particle positions from shared buffer
# # Process C (render):
# #   draw particles from the same SSBO (no readback needed)

# verify data
my @p0 = $buf->slice(0, 4);
printf "particle 0: (%.2f, %.2f, %.2f, w=%.1f)\n", @p0;
my @p500 = $buf->slice(2000, 4);
printf "particle 500: (%.2f, %.2f, %.2f, w=%.1f)\n", @p500;
