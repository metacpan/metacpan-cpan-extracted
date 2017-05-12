#!/usr/bin/env perl

# This fancy thing is a looper!
#
# Notes are entered using xmousepos. On my touchscreen this is easy.
#
# Loops are recorded/played by keypressess of letters

use strict;
use Audio::NoiseGen qw( :all );
use List::Util qw( sum );
use Term::ReadKey;

ReadMode 3;
END { ReadMode 0 }

sub looper {
  my %params = Audio::NoiseGen::generalize( @_ );
  my %loops = ();
  my %record_loops = ();
  my %play_loops = ();
  my %play_oneshot = ();

  my $c = 0;
  sub {
    my $sample = $params{gen}->();

    # Look for action
    my $key = ($c++ % 2000) || ReadKey(-1); # not too often
    exit if defined $key && $key =~ /q/i;
    if(defined $key && $key =~ /[a-z]/) {
      # Check to see if it is being recorded
      if(defined $record_loops{$key}) {
        print "Saving $key\n";
        $loops{$key} = $record_loops{$key};
        print "Playing $key\n";
        $play_loops{$key} = [ @{ $record_loops{$key} } ];
        delete $record_loops{$key};
      } else {
        print "Recording $key\n";
        delete $play_loops{$key};
        $record_loops{$key} = [];
      }
    }
    if(defined $key && $key =~ /[A-Z]/ && defined $loops{lc($key)}) {
      $key = lc $key;
      print "Clearing $key\n";
      delete $play_loops{$key};
      delete $record_loops{$key};
      print "One-shot $key\n";
      $play_oneshot{$key} = [ @{ $loops{$key} } ];
    }

    # Record loops
    foreach my $loop (keys %record_loops) {
      push @{$record_loops{$loop}}, $sample;
    }

    # Output the current sample
    my @output_samples = ($sample);

    # Get samples from play loops
    foreach my $loop (keys %play_loops) {
      if(! @{ $play_loops{$loop} }) {
        # We reached the end. Begin again!
        $play_loops{$loop} = [ @{ $loops{$loop} } ];
      }
      my $loop_sample = shift @{ $play_loops{$loop} };
      push @output_samples, $loop_sample;
    }

    # Get samples from oneshot loops
    foreach my $loop (keys %play_oneshot) {
      # If we run out of samples, stop watching this loop!
      if(! @{ $play_oneshot{$loop} }) {
        delete $play_oneshot{$loop};
        next;
      }
      my $loop_sample = shift @{ $play_oneshot{$loop} };
      push @output_samples, $loop_sample;
    }

    # Compbine and output!
    @output_samples = map { $_ || 0 } @output_samples;
    my $output_sample = sum @output_samples;
    return $output_sample;
    return $output_sample * (1 / (scalar @output_samples)) * 0.8;

  }
}

my $xmousepos;
sub mousefreq {
  my $c = 0;
  my ($x, $y) = (0, 0);
  return sub {
    # Don't update too often
    unless($c++ % 2000) {
      my ($new_x, $new_y) = split(' ', $xmousepos = `xmousepos`);
      # return $x if $x == $new_x;
      $x = $new_x;
      # print "pos: $x, $y\n";
      # Snap to a note!
      my @freqs = values %note_freq;
      @freqs = sort { abs($a - $x) <=> abs($b - $x) } @freqs;
      $x = shift @freqs;
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
    unless($c++ % 2000) {
      ($x, $y) = split(' ', $xmousepos);
      # print "mosevol: " . ($y * (1 / $max)) . "\n";
    }
    return $y * (1 / $max);
  }
}

# Let's do it with JACK
# my @apis = Audio::PortAudio::host_apis();
# my ($jack_api) = grep { $_->name =~ /JACK/ } @apis;
# init($jack_api);

init();

play( gen =>
  looper( gen =>
    amp(
      amount => mousevol(800),
      gen => square(
      #gen => saw(
      # gen => sine(
        freq => mousefreq()
      )
    )
));
