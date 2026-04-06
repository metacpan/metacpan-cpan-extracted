#!/usr/bin/env perl
# Shared vertex + index buffers for indexed GL drawing
#
# Vertex data (F32) and index data (U32) in separate shared buffers.
# Both uploaded to GL as VBO/EBO. A compute process can update the
# mesh while the render process draws it.
use strict;
use warnings;

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::U32;

# --- Build a simple quad mesh ---

# 4 vertices: position(3) + texcoord(2) = 5 floats each = 20 floats
my $verts = Data::Buffer::Shared::F32->new_anon(20);
$verts->set_slice(0,
    # x     y     z     u     v
    -1.0, -1.0,  0.0,  0.0,  0.0,  # bottom-left
     1.0, -1.0,  0.0,  1.0,  0.0,  # bottom-right
     1.0,  1.0,  0.0,  1.0,  1.0,  # top-right
    -1.0,  1.0,  0.0,  0.0,  1.0,  # top-left
);

# 6 indices (2 triangles)
my $indices = Data::Buffer::Shared::U32->new_anon(6);
$indices->set_slice(0, 0, 1, 2, 2, 3, 0);

my $vert_ref = $verts->as_scalar;
my $idx_ref = $indices->as_scalar;

printf "vertices: %d floats (%d bytes), stride=%d\n",
    $verts->capacity, length($$vert_ref), 5 * 4;
printf "indices:  %d uint32s (%d bytes)\n",
    $indices->capacity, length($$idx_ref);

# --- With OpenGL::Modern ---
# use OpenGL::Modern qw(:all);
# use OpenGL::Modern::Helpers qw(glGenBuffers_p glGenVertexArrays_p);
#
# my $vao = glGenVertexArrays_p(1);
# glBindVertexArray($vao);
#
# # VBO
# my $vbo = glGenBuffers_p(1);
# glBindBuffer(GL_ARRAY_BUFFER, $vbo);
# glBufferData_p(GL_ARRAY_BUFFER, $$vert_ref, GL_DYNAMIC_DRAW);
#
# # position attribute (location=0): 3 floats, stride=20, offset=0
# glVertexAttribPointer_c(0, 3, GL_FLOAT, GL_FALSE, 20, 0);
# glEnableVertexAttribArray(0);
#
# # texcoord attribute (location=1): 2 floats, stride=20, offset=12
# glVertexAttribPointer_c(1, 2, GL_FLOAT, GL_FALSE, 20, 12);
# glEnableVertexAttribArray(1);
#
# # EBO
# my $ebo = glGenBuffers_p(1);
# glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, $ebo);
# glBufferData_p(GL_ELEMENT_ARRAY_BUFFER, $$idx_ref, GL_STATIC_DRAW);
#
# # Draw:
# glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
#
# # Live update from another process:
# glBufferSubData_p(GL_ARRAY_BUFFER, 0, $$vert_ref);

# --- Verify data ---
my @v = unpack("f<20", $$vert_ref);
for my $i (0..3) {
    printf "  v%d: pos(%.1f,%.1f,%.1f) uv(%.1f,%.1f)\n",
        $i, @v[$i*5..$i*5+4];
}
my @idx = unpack("V6", $$idx_ref);
printf "  triangles: [%s] [%s]\n",
    join(',', @idx[0..2]), join(',', @idx[3..5]);
