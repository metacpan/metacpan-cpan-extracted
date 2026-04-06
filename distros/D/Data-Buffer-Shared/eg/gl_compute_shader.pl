#!/usr/bin/env perl
# Compute shader with SSBO: GPU computes, CPU reads via shared buffer
#
# Full working pattern for GPU↔CPU data exchange using
# Data::Buffer::Shared + OpenGL::Modern compute shaders.
#
# The shared buffer acts as a staging area for SSBO upload/readback,
# making GPU results visible to other processes via mmap.
#
# Requires: OpenGL::Modern, OpenGL::GLUT, GL 4.3+
use strict;
use warnings;

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::U32;

# === Example 1: parallel array operation (GPU map) ===
{
    my $n = 1024;
    my $input  = Data::Buffer::Shared::F32->new_anon($n);
    my $output = Data::Buffer::Shared::F32->new_anon($n);

    # fill input
    for my $i (0..$n-1) { $input->set($i, $i * 0.01) }

    printf "compute shader example: %d elements\n", $n;
    printf "input ptr:  0x%x (%d bytes)\n", $input->ptr, $n * 4;
    printf "output ptr: 0x%x (%d bytes)\n", $output->ptr, $n * 4;

    # --- With OpenGL::Modern ---
    # use OpenGL::Modern qw(:all);
    # use OpenGL::Modern::Helpers qw(glGenBuffers_p);
    #
    # # Compute shader source:
    # my $cs_src = q{
    #     #version 430
    #     layout(local_size_x = 256) in;
    #     layout(std430, binding = 0) readonly buffer Input {
    #         float data_in[];
    #     };
    #     layout(std430, binding = 1) writeonly buffer Output {
    #         float data_out[];
    #     };
    #     void main() {
    #         uint idx = gl_GlobalInvocationID.x;
    #         data_out[idx] = sin(data_in[idx]) * 2.0 + 1.0;
    #     }
    # };
    #
    # # Create SSBOs from shared buffers
    # my ($ssbo_in, $ssbo_out) = glGenBuffers_p(2);
    #
    # glBindBuffer(GL_SHADER_STORAGE_BUFFER, $ssbo_in);
    # glBufferData_c(GL_SHADER_STORAGE_BUFFER, $n * 4, $input->ptr, GL_STATIC_DRAW);
    # glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, $ssbo_in);
    #
    # glBindBuffer(GL_SHADER_STORAGE_BUFFER, $ssbo_out);
    # glBufferData_c(GL_SHADER_STORAGE_BUFFER, $n * 4, 0, GL_DYNAMIC_READ);
    # glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, $ssbo_out);
    #
    # # Dispatch
    # glUseProgram($compute_prog);
    # glDispatchCompute(int($n / 256), 1, 1);
    # glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
    #
    # # Readback into shared buffer
    # glBindBuffer(GL_SHADER_STORAGE_BUFFER, $ssbo_out);
    # glGetBufferSubData_c(GL_SHADER_STORAGE_BUFFER, 0, $n * 4, $output->ptr);
    #
    # # Results now visible to other processes via mmap!
    # printf "output[0] = %.4f (expected sin(0)*2+1 = 1.0)\n", $output->get(0);

    # simulate GPU output
    for my $i (0..$n-1) { $output->set($i, sin($input->get($i)) * 2.0 + 1.0) }
    printf "simulated output[0] = %.4f\n", $output->get(0);
    printf "simulated output[100] = %.4f\n", $output->get(100);
}

# === Example 2: atomic counters in SSBO ===
{
    my $counters = Data::Buffer::Shared::U32->new_anon(4);

    printf "\natomic counter SSBO: %d counters\n", $counters->capacity;

    # --- With OpenGL::Modern ---
    # # Compute shader with atomics:
    # my $cs_src = q{
    #     #version 430
    #     layout(local_size_x = 256) in;
    #     layout(std430, binding = 0) buffer Counters {
    #         uint count_total;
    #         uint count_above_threshold;
    #         uint count_below_threshold;
    #         uint max_val;
    #     };
    #     layout(std430, binding = 1) readonly buffer Data {
    #         float values[];
    #     };
    #     void main() {
    #         uint idx = gl_GlobalInvocationID.x;
    #         atomicAdd(count_total, 1);
    #         if (values[idx] > 0.5)
    #             atomicAdd(count_above_threshold, 1);
    #         else
    #             atomicAdd(count_below_threshold, 1);
    #     }
    # };
    #
    # # Upload zero counters
    # my $ssbo = glGenBuffers_p(1);
    # glBindBuffer(GL_SHADER_STORAGE_BUFFER, $ssbo);
    # glBufferData_c(GL_SHADER_STORAGE_BUFFER, 16, $counters->ptr, GL_DYNAMIC_COPY);
    # glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, $ssbo);
    #
    # # After dispatch + barrier:
    # glGetBufferSubData_c(GL_SHADER_STORAGE_BUFFER, 0, 16, $counters->ptr);
    # printf "total: %d, above: %d, below: %d\n",
    #     $counters->get(0), $counters->get(1), $counters->get(2);
    #
    # # Cross-process: another process can monitor counters in real time
    # # via the same shared buffer path

    $counters->set(0, 1024);
    $counters->set(1, 523);
    $counters->set(2, 501);
    printf "simulated counters: total=%d above=%d below=%d\n",
        $counters->get(0), $counters->get(1), $counters->get(2);
}

# === Example 3: image histogram via compute shader ===
{
    my $histogram = Data::Buffer::Shared::U32->new_anon(256);  # 256 bins

    printf "\nhistogram SSBO: 256 bins (%d bytes)\n", 256 * 4;

    # --- With OpenGL::Modern ---
    # # Shader reads a texture, atomicAdd into histogram bins:
    # # layout(std430, binding = 0) buffer Histogram { uint bins[256]; };
    # # void main() {
    # #     vec4 texel = texelFetch(img, ivec2(gl_GlobalInvocationID.xy), 0);
    # #     uint luma = uint(dot(texel.rgb, vec3(0.299, 0.587, 0.114)) * 255.0);
    # #     atomicAdd(bins[luma], 1);
    # # }
    #
    # # Readback:
    # glGetBufferSubData_c(GL_SHADER_STORAGE_BUFFER, 0, 1024, $histogram->ptr);
    #
    # # Now another process can read the histogram for auto-exposure,
    # # tone mapping, etc.
    # my @bins = $histogram->slice(0, 256);

    printf "histogram ready for GPU compute dispatch\n";
}
