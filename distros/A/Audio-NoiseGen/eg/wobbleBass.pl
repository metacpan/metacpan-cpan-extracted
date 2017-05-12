#!/usr/bin/env perl

use v5.14;
use Audio::NoiseGen ':all';

$| = 1;

use Chart::Clicker;

Audio::NoiseGen::init();

# play( gen =>
  # envelope(
    # attack => 0.1,
    # sustain => 20,
    # release => 0.1,
    # gen => combine( gens => [
      # segment( notes => 'A' ),
      # segment( notes => 'A B' ),
      # segment( notes => 'A B C' ),
      # segment( notes => 'A B C D' ),
      # # segment( notes => 'A B C D E' ),
      # # segment( notes => 'A B C D E F' ),
      # # segment( notes => 'A B C D E F G' ),
      # # segment( notes => 'A B C D E F G A5' ),
      # # segment( notes => 'A B C D E F G A5 B5' ),
      # # segment( notes => 'A B C D E F G A5 B5 C5' ),
  # ])));

my $xmousepos;
sub mousefreq {
  my $c = 0;
  my ($x, $y) = (0, 0);
  return sub {
    # Don't update too often
    unless($c++ % 1000) {
      my ($new_x, $new_y) = split(' ', $xmousepos = `xmousepos`);
      # return $x if $x == $new_x;
      $x = $new_x / 1280;
      print "x: $x\n";
      # print "pos: $x, $y\n";
      # Snap to a note!
      # my @freqs = values %note_freq;
      # @freqs = sort { abs($a - $x) <=> abs($b - $x) } @freqs;
      # # print "Freqs: @freqs\n\n";
      # $x = shift @freqs;
    }
    return $x;
  }
}
sub mousevol {
  my $max = shift;
  my $c = 0;
  my ($x, $y) = (0, 0);
  return sub {
    # Don't update too often
    unless($c++ % 1000) {
      ($x, $y) = split(' ', $xmousepos);
      # print "mosevol: " . ($y * (1 / $max)) . "\n";
    }
    return $y * (1 / $max);
  }
}

# my $lfo = sine( freq => mousefreq() );
my $lfo = mousefreq();
  

play( gen => amp(
  gen => lowpass(
    rc => sub { abs($lfo->())  },
    gen => sine( freq => 220 )
  ),
  amount => mousevol(800)
  )
);

# sub vis {
  # my %p = generalize(@_);
  # my $c = Chart::Clicker->new;
  # my $sample_count = 0;
  # my @sample_cache;
  # sub {
    # my $sample = $p{gen}->();
    # push @sample_cache, $sample;
    # unless(++$sample_count % 80000) {
      # say "Writing graph!";
      # $c->add_data('Samples', \@sample_cache);
      # $c->write_output('vis.png');
      # @sample_cache = ();
      # say "OK... done with that.";
    # }
    # return $sample;
  # }
# }


# my $n = segment( notes => 'A R R' );

# play( gen =>
  # envelope( sustain => 10, gen =>
    # sequence( gens => [
      # lowpass( rc => 1, gen => $n),
      # segment( notes => 'B R' ),
      # lowpass( rc => 0.5, gen => $n),
      # segment( notes => 'B R' ),
      # lowpass( rc => 0.1, gen => $n),
      # segment( notes => 'B R' ),
      # lowpass( rc => 0.01, gen => $n),
      # segment( notes => 'B R' ),
      # lowpass( rc => 0.001, gen => $n),
      # segment( notes => 'R R R R R' ),
    # ])
  # )
# );

# play(
  # # lowpass_gen(

  # sequence_gen(
    # envelope_gen( attack => 0, sustain => 2, release => 0,
      # gen => highpass_gen( gen => white_noise_gen( freq => 440 ) ),
    # ),
  # )
# , 'out.raw');

# exit;

# my $lfo = sine_gen({ freq => 1 });
# my $wobble = sub { $lfo->() * 100 };
# my $wobble_a = envelope_gen(
  # { attack => 0.1, sustain => 0.3, decay => 0.3 },
  # sine_gen({
    # # freq => sub { $wobble->() }
    # freq => sub { $wobble->() + 220 }
    # # freq => 220
  # })
# );

# play(

  # amp_gen(
    # { amount => 0.5 },
    # sequence_gen(
      # $wobble_a,
      # $wobble_a,
      # $wobble_a,
      # # sine_gen({ freq => 1 }),
    # )
  # ),



# , 'out.raw');

