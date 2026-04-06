#!/usr/bin/env perl
# Shared audio waveform buffer for real-time GL visualization
#
# Pattern: audio capture/synthesis writes F32 samples into a ring-style
# shared buffer, GL renderer reads and draws the waveform.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::I64;

my $sample_rate = 44100;
my $buf_samples = 4096;    # ~93ms at 44.1kHz
my $duration = 0.5;        # seconds to simulate

my $audio = Data::Buffer::Shared::F32->new_anon($buf_samples);
my $ctl = Data::Buffer::Shared::I64->new_anon(2); # 0=write_pos, 1=quit
$ctl->create_eventfd;

my $pid = fork();
if ($pid == 0) {
    # === AUDIO PRODUCER (e.g. PortAudio callback, synthesizer) ===
    my $chunk = 256;  # samples per write
    my $pos = 0;
    my $total = int($sample_rate * $duration);
    my $freq = 440.0;  # A4

    for (my $t = 0; $t < $total; $t += $chunk) {
        # generate a sine wave chunk
        my @samples;
        for my $i (0..$chunk-1) {
            my $phase = ($t + $i) / $sample_rate * $freq * 2.0 * 3.14159265;
            push @samples, sin($phase) * 0.8;
        }

        # write into circular position
        my $wrap_pos = $pos % $buf_samples;
        if ($wrap_pos + $chunk <= $buf_samples) {
            $audio->set_slice($wrap_pos, @samples);
        } else {
            # wrap around
            my $first = $buf_samples - $wrap_pos;
            $audio->set_slice($wrap_pos, @samples[0..$first-1]);
            $audio->set_slice(0, @samples[$first..$#samples]);
        }
        $pos += $chunk;
        $ctl->set(0, $pos);
        $ctl->notify;
    }
    $ctl->set(1, 1);
    $ctl->notify;
    _exit(0);
}

# === GL WAVEFORM RENDERER (simulated) ===
my $ref = $audio->as_scalar;
my $frames = 0;
my $t0 = time();

while (!$ctl->get(1)) {
    my $n = $ctl->wait_notify;
    unless (defined $n) { sleep 0.001; next }

    # --- With OpenGL::Modern ---
    # Upload waveform to a VBO for line strip rendering:
    #
    # glBindBuffer(GL_ARRAY_BUFFER, $waveform_vbo);
    # glBufferSubData_p(GL_ARRAY_BUFFER, 0, $$ref);
    #
    # # vertex shader: x = gl_VertexID / buf_samples * 2.0 - 1.0
    # #                y = sample_value
    # glDrawArrays(GL_LINE_STRIP, 0, $buf_samples);

    # Simulated: just read peak amplitude
    my @samples = unpack("f<$buf_samples", $$ref);
    my $peak = 0;
    for (@samples) { $peak = abs($_) if abs($_) > $peak }
    $frames++;
}
waitpid($pid, 0);

my $elapsed = time() - $t0;
my $write_pos = $ctl->get(0);
printf "audio: %d Hz, %d samples buffer (%.1fms)\n",
    $sample_rate, $buf_samples, $buf_samples / $sample_rate * 1000;
printf "produced: %d samples (%.3fs)\n", $write_pos, $write_pos / $sample_rate;
printf "render frames: %d (%.0f fps)\n", $frames, $frames / ($elapsed || 1);

# verify waveform content
my @last = $audio->slice(0, 8);
printf "first 8 samples: %s\n", join(' ', map { sprintf("%.3f", $_) } @last);
