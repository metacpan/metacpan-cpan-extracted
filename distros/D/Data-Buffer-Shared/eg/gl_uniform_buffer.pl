#!/usr/bin/env perl
# Shared F32 buffer as a GL Uniform Buffer Object (UBO)
#
# UBOs allow sharing uniform data (matrices, lighting, camera params)
# between shaders. A shared buffer lets one process update camera/scene
# params while another renders.
use strict;
use warnings;

use Data::Buffer::Shared::F32;

# std140 layout: mat4 (16 floats) + vec4 (4 floats) + vec4 (4 floats) = 24 floats
# Matches a typical shader uniform block:
#   layout(std140) uniform SceneData {
#       mat4 viewProjection;   // 64 bytes
#       vec4 lightPos;         // 16 bytes
#       vec4 lightColor;       // 16 bytes
#   };
my $ubo = Data::Buffer::Shared::F32->new_anon(24);

# identity matrix (column-major, std140)
my @identity = (
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
);
$ubo->set_slice(0, @identity);

# light position (vec4)
$ubo->set_slice(16, 10.0, 20.0, 30.0, 1.0);

# light color (vec4)
$ubo->set_slice(20, 1.0, 0.9, 0.8, 1.0);

my $ref = $ubo->as_scalar;
printf "UBO size: %d bytes (std140 aligned)\n", length($$ref);

# --- With OpenGL::Modern ---
# my $ubo_id = glGenBuffers_p(1);
# glBindBuffer(GL_UNIFORM_BUFFER, $ubo_id);
# glBufferData_p(GL_UNIFORM_BUFFER, $$ref, GL_DYNAMIC_DRAW);
# glBindBufferBase(GL_UNIFORM_BUFFER, 0, $ubo_id);  # binding point 0
#
# # Per-frame update (e.g. camera moved):
# $ubo->lock_wr;
# $ubo->set_slice(0, @new_view_projection_matrix);
# $ubo->unlock_wr;
# glBufferSubData_p(GL_UNIFORM_BUFFER, 0, $$ref);

# --- Multiprocess pattern ---
# Process A (camera/physics):
#   my $ubo = Data::Buffer::Shared::F32->new('/tmp/scene.shm', 24);
#   $ubo->create_eventfd;
#   while (1) {
#       $ubo->lock_wr;
#       $ubo->set_slice(0, @updated_vp_matrix);
#       $ubo->set_slice(16, @updated_light_pos);
#       $ubo->unlock_wr;
#       $ubo->notify;
#   }
#
# Process B (renderer):
#   my $ubo = Data::Buffer::Shared::F32->new('/tmp/scene.shm', 24);
#   my $ref = $ubo->as_scalar;
#   while (1) {
#       if (defined $ubo->wait_notify) {
#           glBufferSubData_p(GL_UNIFORM_BUFFER, 0, $$ref);
#       }
#       draw_scene();
#   }

# verify
my @mat = unpack("f<16", substr($$ref, 0, 64));
printf "viewProjection[0][0] = %.1f (identity)\n", $mat[0];
my @lpos = unpack("f<4", substr($$ref, 64, 16));
printf "lightPos = (%.1f, %.1f, %.1f)\n", @lpos[0..2];
my @lcol = unpack("f<4", substr($$ref, 80, 16));
printf "lightColor = (%.1f, %.1f, %.1f)\n", @lcol[0..2];
