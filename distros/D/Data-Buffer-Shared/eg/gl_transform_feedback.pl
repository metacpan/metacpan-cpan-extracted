#!/usr/bin/env perl
# Transform feedback: capture vertex shader output into shared buffer
#
# Transform feedback writes transformed vertices back into a buffer
# instead of (or in addition to) rasterizing them. Use cases:
#   - GPU particle updates (position/velocity computed in vertex shader)
#   - Geometry caching (transform once, draw many times)
#   - Stream-out for cross-process access via shared buffer
#
# Pipeline:
#   1. Shared F32 buffer holds particle state (pos + vel)
#   2. Upload to GL buffer via ptr()
#   3. Vertex shader updates physics
#   4. Transform feedback captures output into a second GL buffer
#   5. Readback into shared buffer for CPU/cross-process access
#
# Requires: OpenGL::Modern, OpenGL::GLUT (for GL context)
use strict;
use warnings;

use Data::Buffer::Shared::F32;

# 500 particles: position(3) + velocity(3) = 6 floats each
my $nparticles = 500;
my $floats_per = 6;
my $total_floats = $nparticles * $floats_per;

# double buffer: input and output
my $buf_in  = Data::Buffer::Shared::F32->new_anon($total_floats);
my $buf_out = Data::Buffer::Shared::F32->new_anon($total_floats);

# initialize: positions on a sphere, velocities outward
for my $i (0..$nparticles-1) {
    my $theta = rand(6.28318);
    my $phi = rand(3.14159);
    my $r = 5.0;
    my $base = $i * $floats_per;
    $buf_in->set($base + 0, $r * sin($phi) * cos($theta));  # px
    $buf_in->set($base + 1, $r * sin($phi) * sin($theta));  # py
    $buf_in->set($base + 2, $r * cos($phi));                 # pz
    $buf_in->set($base + 3, sin($phi) * cos($theta) * 0.1); # vx
    $buf_in->set($base + 4, sin($phi) * sin($theta) * 0.1); # vy
    $buf_in->set($base + 5, cos($phi) * 0.1);               # vz
}

my $byte_size = $total_floats * 4;
printf "transform feedback: %d particles, %d bytes\n", $nparticles, $byte_size;
printf "buf_in ptr:  0x%x\n", $buf_in->ptr;
printf "buf_out ptr: 0x%x\n", $buf_out->ptr;

# --- With OpenGL::Modern ---
# use OpenGL::Modern qw(:all);
# use OpenGL::Modern::Helpers qw(glGenBuffers_p glGenVertexArrays_p);
#
# # Vertex shader for physics update:
# my $vs_src = q{
#     #version 330
#     layout(location = 0) in vec3 inPos;
#     layout(location = 1) in vec3 inVel;
#     out vec3 outPos;
#     out vec3 outVel;
#     uniform float dt;
#     void main() {
#         vec3 gravity = vec3(0, -9.8, 0);
#         outVel = inVel + gravity * dt;
#         outPos = inPos + outVel * dt;
#     }
# };
#
# # Set up transform feedback varyings BEFORE linking
# glTransformFeedbackVaryings_p($program, 2,
#     ["outPos", "outVel"], GL_INTERLEAVED_ATTRIBS);
# glLinkProgram($program);
#
# # Create input VBO from shared buffer
# my $vbo_in = glGenBuffers_p(1);
# glBindBuffer(GL_ARRAY_BUFFER, $vbo_in);
# glBufferData_c(GL_ARRAY_BUFFER, $byte_size, $buf_in->ptr, GL_STREAM_DRAW);
#
# # Create output TFB buffer
# my $vbo_out = glGenBuffers_p(1);
# glBindBuffer(GL_TRANSFORM_FEEDBACK_BUFFER, $vbo_out);
# glBufferData_c(GL_TRANSFORM_FEEDBACK_BUFFER, $byte_size, 0, GL_STREAM_READ);
#
# # Set up VAO
# my $vao = glGenVertexArrays_p(1);
# glBindVertexArray($vao);
# glBindBuffer(GL_ARRAY_BUFFER, $vbo_in);
# glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 24, 0);   # pos
# glVertexAttribPointer_c(1, 3, GL_FLOAT, GL_FALSE, 24, 12);  # vel
# glEnableVertexAttribArray(0);
# glEnableVertexAttribArray(1);
#
# # === Per-frame update ===
# glUseProgram($program);
# glUniform1f($dt_loc, 0.016);  # 60fps timestep
#
# glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, $vbo_out);
# glEnable(GL_RASTERIZER_DISCARD);  # no rendering, just capture
# glBeginTransformFeedback(GL_POINTS);
# glDrawArrays(GL_POINTS, 0, $nparticles);
# glEndTransformFeedback();
# glDisable(GL_RASTERIZER_DISCARD);
#
# # Readback output into shared buffer
# glBindBuffer(GL_TRANSFORM_FEEDBACK_BUFFER, $vbo_out);
# glGetBufferSubData_c(GL_TRANSFORM_FEEDBACK_BUFFER, 0,
#                       $byte_size, $buf_out->ptr);
#
# # Now buf_out has GPU-computed positions/velocities
# # Another process can read them:
# printf "particle 0 new pos: (%.2f, %.2f, %.2f)\n",
#     $buf_out->get(0), $buf_out->get(1), $buf_out->get(2);
#
# # Ping-pong: swap buffers for next frame
# # glBufferSubData_c(GL_ARRAY_BUFFER, 0, $byte_size, $buf_out->ptr);

# verify initial data
my @p0 = $buf_in->slice(0, 6);
printf "particle 0 init: pos(%.2f,%.2f,%.2f) vel(%.3f,%.3f,%.3f)\n", @p0;
my @p100 = $buf_in->slice(600, 6);
printf "particle 100 init: pos(%.2f,%.2f,%.2f) vel(%.3f,%.3f,%.3f)\n", @p100;
