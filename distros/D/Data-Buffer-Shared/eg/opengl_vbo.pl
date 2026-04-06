#!/usr/bin/env perl
# Upload shared buffer directly to OpenGL VBO via ptr()
#
# The buffer's as_scalar or ptr gives zero-copy access to the mmap'd
# data, which can be passed directly to glBufferData/glBufferSubData.
#
# Requires: OpenGL::Modern (or OpenGL), OpenGL::GLUT
use strict;
use warnings;

use Data::Buffer::Shared::F32;

# 3 vertices * (x,y,z) = 9 floats
my $verts = Data::Buffer::Shared::F32->new_anon(9);
$verts->set_slice(0,
    -0.5, -0.5, 0.0,   # vertex 0
     0.5, -0.5, 0.0,   # vertex 1
     0.0,  0.5, 0.0,   # vertex 2
);

# zero-copy scalar ref — pass directly to GL
my $data_ref = $verts->as_scalar;

printf "vertex buffer: %d floats, %d bytes\n",
    $verts->capacity, length($$data_ref);

# --- With OpenGL::Modern ---
# use OpenGL::Modern qw(:all);
# use OpenGL::Modern::Helpers qw(glGenBuffers_p glBufferData_p);
#
# my $vbo = glGenBuffers_p(1);
# glBindBuffer(GL_ARRAY_BUFFER, $vbo);
# glBufferData_p(GL_ARRAY_BUFFER, $$data_ref, GL_STATIC_DRAW);
#
# # After another process updates the shared buffer:
# glBufferSubData_p(GL_ARRAY_BUFFER, 0, $$data_ref);

# --- With OpenGL (legacy) ---
# use OpenGL qw(:all);
#
# my ($vbo) = glGenBuffersARB_p(1);
# glBindBufferARB(GL_ARRAY_BUFFER_ARB, $vbo);
# glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $$data_ref, GL_DYNAMIC_DRAW_ARB);

# --- Live update pattern ---
# Process A (compute):
#   my $buf = Data::Buffer::Shared::F32->new('/tmp/verts.shm', 9);
#   $buf->create_eventfd;
#   while (1) {
#       # update vertex positions...
#       $buf->set_slice(0, @new_positions);
#       $buf->notify;
#   }
#
# Process B (render):
#   my $buf = Data::Buffer::Shared::F32->new('/tmp/verts.shm', 9);
#   $buf->attach_eventfd($efd);  # received via SCM_RIGHTS
#   my $ref = $buf->as_scalar;
#   while (1) {
#       if (defined $buf->wait_notify) {
#           glBufferSubData_p(GL_ARRAY_BUFFER, 0, $$ref);  # zero-copy upload
#       }
#       render_frame();
#   }

print "example vertex data (packed floats):\n";
my @floats = unpack("f<9", $$data_ref);
for my $i (0..2) {
    printf "  v%d: (%.1f, %.1f, %.1f)\n", $i, @floats[$i*3..$i*3+2];
}
