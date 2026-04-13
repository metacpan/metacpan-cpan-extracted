#!/usr/bin/env perl
# OpenGL waveform display backed by shared ring buffer
#
# Pattern: producer writes F64 audio/sensor samples into ring,
# renderer reads the latest N samples for waveform display.
# Shows how to snapshot ring data for GL vertex upload.
#
# This is a structural example — actual rendering requires
# OpenGL::Modern + GLFW/SDL. The data flow is what matters.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::RingBuffer::Shared;
$| = 1;

my $SAMPLES = 256;  # waveform display width
my $ring = Data::RingBuffer::Shared::F64->new(undef, $SAMPLES);

# producer: generate waveform data (sine + harmonics)
my $pid = fork // die;
if ($pid == 0) {
    for my $i (0..999) {
        my $t = $i * 0.01;
        my $sample = sin($t * 2.0) * 0.5
                   + sin($t * 5.0) * 0.3
                   + sin($t * 13.0) * 0.1;
        $ring->write($sample);
        sleep 0.002;
    }
    _exit(0);
}

# renderer: snapshot ring for display
# In real OpenGL:
#   my @samples = $ring->to_list;
#   my $packed = pack('f*', map { $_ / 2.0 } @samples);  # normalize to [-1,1]
#   glBindBuffer(GL_ARRAY_BUFFER, $vbo);
#   glBufferData_s(GL_ARRAY_BUFFER, $packed, GL_STREAM_DRAW);
#   glDrawArrays(GL_LINE_STRIP, 0, scalar @samples);

for my $frame (1..8) {
    sleep 0.15;
    my @samples = $ring->to_list;
    next unless @samples > 10;

    # compute waveform stats for text display
    my ($min, $max, $sum) = ($samples[0], $samples[0], 0);
    for (@samples) {
        $min = $_ if $_ < $min;
        $max = $_ if $_ > $max;
        $sum += $_;
    }
    my $avg = $sum / @samples;

    # ASCII mini-waveform (sample every 8th point)
    my $wave = '';
    for (my $i = 0; $i < @samples; $i += int(@samples / 32)) {
        my $v = ($samples[$i] + 1) / 2;  # normalize 0..1
        $v = 0 if $v < 0; $v = 1 if $v > 1;
        my $col = int($v * 7);
        $wave .= [' ', '.', '-', '~', '=', '#', '@', 'M']->[$col];
    }

    printf "  frame %d: n=%3d min=%+.2f max=%+.2f [%s]\n",
        $frame, scalar @samples, $min, $max, $wave;
}

waitpid($pid, 0);
printf "\ndone: %d samples written, %d in ring\n", $ring->count, $ring->size;
