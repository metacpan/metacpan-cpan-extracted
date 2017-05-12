package Audio::NoiseGen;

use v5.10;
use strict;
use warnings;
use parent 'Exporter';
use Audio::PortAudio;
use List::Util qw( sum );
use List::MoreUtils qw( none );

our $VERSION = '0.04';

=head1 NAME

Audio::NoiseGen - Unit Generator Based Sound Synthesizer

=head1 SYNOPSIS

  use Audio::NoiseGen ':all';

  # Connect to your sound engine/hardware
  Audio::NoiseGen::init();

  play( gen =>
    envelope(
      attack => 0.2,
      sustain => 14.5,
      release => 0.2,
      gen =>
        combine(
          gens => [
            segment(notes => '
              E D C D
              E E E R
              D D D R
              E E E R
              E D C D
              E E E/2 E
              D D E D C
            '),
            segment(notes => 'A2 R R R'),
            segment(notes => 'C3/2 E3/4 E3/4 C3/2 F3 R'),
          ],
        ),
    )
  );

=head1 DESCRIPTION

"Unit Generators" have long been a method to synthesize digital sound (music, dare I say). This module provides a suite of such generators. You first create an instance of a generator, and then each time that instance is invoked it returns a sample.

=head1 PACKAGE VARIABLES

These variables can be exported if you want. They are used by some of the generators to help calculate things like timing.

=over 4

=item * C<$sample_rate> - samples/second sent to soundcard

=item * C<$time_step> - 1/$sample_rate to ease calculations

=item * C<$pi> - Er.... pi :)

=item * C<%note_freq> - map of note names to frequencies

=back

=cut

our ($sample_rate, $time_step, $stream);
my $pi = 3.14159265358979323846;

# Note => Frequency (Hz)
our %note_freq = (
  'C0'  => 16.35,   'C#0' => 17.32,   'Db0' => 17.32,
  'D0'  => 18.35,   'D#0' => 19.45,   'Eb0' => 19.45,
  'E0'  => 20.60,   'F0'  => 21.83,   'F#0' => 23.12,
  'Gb0' => 23.12,   'G0'  => 24.50,   'G#0' => 25.96,
  'Ab0' => 25.96,   'A0'  => 27.50,   'A#0' => 29.14,
  'Bb0' => 29.14,   'B0'  => 30.87,   'C1'  => 32.70,
  'C#1' => 34.65,   'Db1' => 34.65,   'D1'  => 36.71,
  'D#1' => 38.89,   'Eb1' => 38.89,   'E1'  => 41.20,
  'F1'  => 43.65,   'F#1' => 46.25,   'Gb1' => 46.25,
  'G1'  => 49.00,   'G#1' => 51.91,   'Ab1' => 51.91,
  'A1'  => 55.00,   'A#1' => 58.27,   'Bb1' => 58.27,
  'B1'  => 61.74,   'C2'  => 65.41,   'C#2' => 69.30,
  'Db2' => 69.30,   'D2'  => 73.42,   'D#2' => 77.78,
  'Eb2' => 77.78,   'E2'  => 82.41,   'F2'  => 87.31,
  'F#2' => 92.50,   'Gb2' => 92.50,   'G2'  => 98.00,
  'G#2' => 103.83,  'Ab2' => 103.83,  'A2'  => 110.00,
  'A#2' => 116.54,  'Bb2' => 116.54,  'B2'  => 123.47,
  'C3'  => 130.81,  'C#3' => 138.59,  'Db3' => 138.59,
  'D3'  => 146.83,  'D#3' => 155.56,  'Eb3' => 155.56,
  'E3'  => 164.81,  'F3'  => 174.61,  'F#3' => 185.00,
  'Gb3' => 185.00,  'G3'  => 196.00,  'G#3' => 207.65,
  'Ab3' => 207.65,  'A3'  => 220.00,  'A#3' => 233.08,
  'Bb3' => 233.08,  'B3'  => 246.94,  'C4'  => 261.63,
  'C#4' => 277.18,  'Db4' => 277.18,  'D4'  => 293.66,
  'D#4' => 311.13,  'Eb4' => 311.13,  'E4'  => 329.63,
  'F4'  => 349.23,  'F#4' => 369.99,  'Gb4' => 369.99,
  'G4'  => 392.00,  'G#4' => 415.30,  'Ab4' => 415.30,
  'A4'  => 440.00,  'A#4' => 466.16,  'Bb4' => 466.16,
  'B4'  => 493.88,  'C5'  => 523.25,  'C#5' => 554.37,
  'Db5' => 554.37,  'D5'  => 587.33,  'D#5' => 622.25,
  'Eb5' => 622.25,  'E5'  => 659.26,  'F5'  => 698.46,
  'F#5' => 739.99,  'Gb5' => 739.99,  'G5'  => 783.99,
  'G#5' => 830.61,  'Ab5' => 830.61,  'A5'  => 880.00,
  'A#5' => 932.33,  'Bb5' => 932.33,  'B5'  => 987.77,
  'C6'  => 1046.50, 'C#6' => 1108.73, 'Db6' => 1108.73,
  'D6'  => 1174.66, 'D#6' => 1244.51, 'Eb6' => 1244.51,
  'E6'  => 1318.51, 'F6'  => 1396.91, 'F#6' => 1479.98,
  'Gb6' => 1479.98, 'G6'  => 1567.98, 'G#6' => 1661.22,
  'Ab6' => 1661.22, 'A6'  => 1760.00, 'A#6' => 1864.66,
  'Bb6' => 1864.66, 'B6'  => 1975.53, 'C7'  => 2093.00,
  'C#7' => 2217.46, 'Db7' => 2217.46, 'D7'  => 2349.32,
  'D#7' => 2489.02, 'Eb7' => 2489.02, 'E7'  => 2637.02,
  'F7'  => 2793.83, 'F#7' => 2959.96, 'Gb7' => 2959.96,
  'G7'  => 3135.96, 'G#7' => 3322.44, 'Ab7' => 3322.44,
  'A7'  => 3520.00, 'A#7' => 3729.31, 'Bb7' => 3729.31,
  'B7'  => 3951.07, 'C8'  => 4186.01, 'C#8' => 4434.92,
  'Db8' => 4434.92, 'D8'  => 4698.64, 'D#8' => 4978.03,
  'Eb8' => 4978.03,
);

our @EXPORT_OK = qw(
  $sample_rate
  $time_step
  $stream
  %note_freq
  init
  play
  G
  sine
  silence
  noise
  white_noise
  triangle
  square
  envelope
  combine
  split
  sequence
  note
  rest
  segment
  formula
  hardlimit
  amp
  oneshot
  lowpass
  highpass
  generalize
);

our %EXPORT_TAGS = (
  all => [ @EXPORT_OK ]
);

=head1 INITIALIZATION AND PLAY

=head2 init($api, $device, $sample_rate)

This sets up our L<Audio::PortAudio> interface. All parameters are optional, and without any you will get the default provided by PortAudio.

=cut

sub init {
  my $api = shift || Audio::PortAudio::default_host_api();
  my $device = shift || $api->default_output_device;
  $sample_rate = shift || 48000;
  # $sample_rate = shift || 20000;
  $time_step = (1/$sample_rate); # 2 * (1/48000) = 0.0000416666
  $stream = $device->open_write_stream(
    {
      channel_count => 1,
    },
    $sample_rate,
    8000, # some sort of buffer size?
    # 0
  );
}

# sub import {
  # my $class = shift;
  # # if(grep { /^:init$/ } @_) {
    # # Audio::NoiseGen::init();
  # # }
  # $class->SUPER::import(@_);
# }

sub log10 {
  my $n = shift;
  return log($n)/log(10);
}

sub db {
  my $sample = shift;
  return (20 * log10(abs($sample)+0.00000001));
}

=head2 play(gen => $gen, filename => $filename)

C<$filename> is optional.

Invokes the C<$gen> and sends the resulting samples to the output device (soundcard).

=cut

# Play a sequence until we get an undef
my $mon = 0;
sub play {
  my %params = generalize( @_ );
  my $gen = $params{gen};
  my $filename = $params{filename} && $params{filename}->();
  # sox -r 48k -e floating-point -b 32 out.raw out.wav
  my $file;
  if($filename) {
    open $file, '>', $filename
      or die "Error opening $filename: $!";
  }
  while (1) {
    my $raw_sample = '';
    for(1..1000) {
    # while(1) {
      my $sample = $gen->();
      if(defined $sample && ($sample > 1 || $sample < -1)) {
        print "CLIP: $sample\n";
        $sample = $sample > 1 ? 1 : -1;
      }
      # print "Sample: $sample\n";
      if(!defined $sample) {
        $stream->write($raw_sample);
        print $file $raw_sample if $file;
        return;
      }

      # printf "dB: %0.05f\n", db($sample)
        # unless $mon++ % 100;
        
      $raw_sample .= pack "f*", $sample;
    }
      # unless $mon++ % 1000;
    # print "Sending sample block...";
    my $write_available = $stream->write_available;
    # printf "Buffer: %d\n", $write_available
        # if $write_available < 1000;
        # unless $mon++ % 100;
    $stream->write($raw_sample);
    print $file $raw_sample if $file;
    # print "sent.\n";
  }
}

# Turn constants into generators
sub generalize {
  my %params = @_;
  foreach my $name (keys %params) {
    unless(ref $params{$name} eq 'CODE') {
      my $val = $params{$name};
      $params{$name} = sub { $val };
    }
  }
  return %params;
}

=head1 UNIT GENERATORS

=head2 sine({ freq => 440 })

Generates a sine-wave.

=cut

sub sine {
  my %params = generalize( freq => 440, @_ );

  my $angle = 0;
  return sub {
    my $sample = sin($angle);
    my $freq = $params{freq}->() || 0;
    $angle += 2 * $pi * $time_step * $freq;
    return $sample;
  };
}

sub hardlimit {
  my %params = generalize( level => 1, @_ );
  return sub {
    my $sample = $params{gen}->();
    my $level = $params{level}->();
    if($sample > $level) {
      return $level;
    }
    if($sample < -1*$level) {
      return -1 * $level;
    }
    return $sample;
  }
}

=head2 amp( amount => 0.5, gen => $g )

Amplify the output of C<$g>. If amount is greather than 1 this will make it louder, less than one to make it quieter.

=cut

sub amp {
  my %params = generalize( amount => 1, @_ );
  return sub {
    my $sample = $params{gen}->();
    defined $sample
      ? $sample * $params{amount}->()
      : undef;
  }
}

=head2 silence()

Just return silence forever.

=cut

sub silence {
  return sub {
    return 0;
  };
}

sub noise {
  my %params = generalize( delta => 0.01, @_ );
  my $sample = 0;
  return sub {
    my $change = int(rand(2)) > 1 ? 1 : -1;
    $sample += $change * $params{delta}->();
    if($sample > 1) {
      $sample = 1;
    }
    if($sample < -1) {
      $sample = -1;
    }
    return $sample;
  };
}

=head2 white_noise()

Return random samples.

=cut

sub white_noise {
  return sub {
    return (rand(2) - 1);
  };
}

=head2 triangle( freq => $freq )

Triangle wave.

=cut

sub triangle {
  my %params = generalize( freq => 440, @_ );
  my $current_sample = 0;
  my $current_freq = 0;
  my $direction = 1;
  return sub {
    my $sample_count = (1 / $params{freq}->()) * $sample_rate;
    my $sample = $current_freq;
    $current_freq += $direction * (4 / $sample_count);
    if($current_freq >= 1) {
      $current_freq = 1;
      $direction = -1;
    }
    if($current_freq <= -1) {
      $current_freq = -1;
      $direction = 1;
    }
    return $current_freq;
  };
}


=head2 square( freq => $freq )

Square wave.

=cut

sub square {
  my %params = generalize( freq => 440, @_ );
  my $current_sample = 0;
  my $current_freq = 0;
  my $sample_count = 1;
  return sub {
    my $freq = $params{freq}->();
    return 0 if ! defined $freq;

    # Only calculate sample count if freq changes
    if($current_freq != $freq) {
      $sample_count = $sample_rate / $freq / 2;
      $current_freq = $freq;
    }
    $current_sample++;
    if($current_sample > $sample_count) {
      $current_sample = - $sample_count;
    }
    if($current_sample < 0) {
      return 1;
    }
    if($current_sample >= $sample_count) {
      return -1;
    }
  };
}

=head2 envelope( gen => $g, ... )

Build up a simple envelope. So far this supports attack, sustain, and release (I need to implement decay).

This will fade the volume up for $attack seconds (linear), keep it there for $sustain seconds, and then fade down for $release seconds (linear).

Returns undef at the end of the release.

=cut

sub envelope {
  my %params = generalize(
    attack => 0,
    sustain => 0,
    release => 0,
    @_
  );

  my $attack_sample_count  = $params{attack}->()  * $sample_rate;
  my $sustain_sample_count = $params{sustain}->() * $sample_rate;
  my $release_sample_count = $params{release}->() * $sample_rate;

  my $mode = 'attack';
  my $current_sample = 0;
  return sub {
    $current_sample++;
    if($mode eq 'attack') {
      if($current_sample > $attack_sample_count) {
        $current_sample = 1;
        $mode = 'sustain';
      } else {
        my $scale = $current_sample / $attack_sample_count;
        return $params{gen}->() * $scale;
      }
    }
    if($mode eq 'sustain') {
      if($current_sample > $sustain_sample_count) {
        $current_sample = 1;
        $mode = 'release';
      } else {
        return $params{gen}->();
      }
    }
    if($mode eq 'release') {
      if($current_sample > $release_sample_count) {
        $current_sample = 1;
        $mode = 'attack';
        return undef;
      } else {
        my $scale = 1 - ($current_sample / $release_sample_count);
        return $params{gen}->() * $scale;
      }
    }
  };
}

=head2 combine( gens => [ ... ] )

Plays each of the provided generators all at once.

Once all the generators return undef, combine will return undef. Subsequent calls will start it over.

=cut

sub combine {
  my %params = generalize(@_);
  my @gens = @{ $params{gens}->() };
  my @g;
  return sub {
    (@g) = @gens unless @g;
    my @samples = map { $_->() } @g;
    if(none { defined } @samples) {
      (@g) = @gens;
      return undef;
    } else {
      @samples = map { $_ || 0 } @samples;
      my $sample = sum @samples;
      return $sample * (1 / (scalar @gens));
    }
  };
}

sub split {
  my %params = generalize( count => 2, @_ );
  return sub {
    my $sample = $params{gen}->();
    return ($sample) x $params{count}->();
  }
}

=head2 sequence( gens => [ ... ] )

Play a list of generators, one after another. Plays the first generator until it returns undef, then goes on to the second, and so on. Returns undef when it completes the last generator in it's sequence, and then keeps returning undef after that.

=cut

sub sequence {
  my %params = generalize( @_ );
  my @gens = @{ $params{gens}->() };
  my @g;
  return sub {
    (@g) = @gens unless @g;
    while(@g) {
      my $sample = $g[0]->();
      if(defined $sample) {
        return $sample;
      } else {
        shift @g;
      }
    }
    (@g) = @gens;
    return undef;
  };
}

sub oneshot {
  my %params = generalize( @_ );
  my $gen = $params{gen};
  sub {
    my $sample = $params{gen}->();
    if(!defined $sample) {
      $gen = silence();
      $sample = $params{gen}->();
    }
    return $sample;
  }
}

=head2 note( note => 'C#' )

Plays a named note, looking it up in %note_freq. Actually builds an envelope for the note, so it can take a subref 'instrument' to use for the actual sound.

Note that 'instrument' isn't a generator, it is a generator-creator that will be passed a freq. The default is C<< \&sine >>. Tricky.

You can also pass any of the evelope parameters. It defaults to zero attack and release, and 0.1 second sustain.

=cut

sub note {
  my %params = generalize(
    note    => 'A4',
    # gen     => \&triangle,
    # gen     => \&square,
    instrument => \&sine,
    sustain => 0.1,
    @_
  );
  my ($c, $e);
  return sub {
    $c ||= $params{instrument}->(
      freq => $note_freq{$params{note}->()}
    );
    $e ||= envelope( %params, gen => $c );
    my $sample = $e->();
    if(! defined $sample) {
      undef $c;
      undef $e;
    }
    return $sample;
  }
}

=head2 rest( length => 3 )

Play silence for a fixed set of time, 'length', in seconds.

=cut

sub rest {
  my %params = generalize( length => 0, @_ );
  my $silence = silence();
  return envelope( sustain => $params{length}, gen => $silence );
}

=head2 segment( notes => 'A B C#' )

Generate a sequence of notes by parsing the 'notes' param. Pretty minimal for now.

=cut

sub segment {
  my %params = generalize( @_ );
  my @notes;
  my $cur_gen;
  my $last_sample;
  return sub {
    if(!@notes && ! defined $last_sample) {
      my $notes = $params{notes}->();
      $notes =~ s/^\s+//;
      $notes =~ s/\s+$//;
      push @notes, split(/\s+/, $notes);
    }
    if(! defined $last_sample && @notes) {
      my $base = 0.5;
      my $note = shift @notes;
      my ($n, $f) = split '/', $note;
      $f ||= 1;
      my $l = $base / $f;
      unless( $n =~ /\d$/ ) {
        $n .= '4';
      }
      if($n =~ /^R/) {
        $cur_gen = rest(length => $l);
      } else {
        $cur_gen = note(
          note    => $n,
          attack  => 0.01,
          sustain => $l,
          release => 0.01
        );
      }
    }
    $last_sample = $cur_gen->();
    return $last_sample || 0;
  }
}

=head2 formula( formula => sub { $_*(42&$_>>10) } )

Plays a formula. Takes 'formula', 'bits', and 'sample_rate'. 'bits' defaults to 8, 'sample_rate' defaults to 8000.

Formula uses C<< $_ >> instead of 't', but is otherwise similar to what is described at L<http://countercomplex.blogspot.com/2011/10/algorithmic-symphonies-from-one-line-of.html>.

=cut

sub formula {
  my %params = generalize(
    bits        => 8,
    sample_rate => 8000,
    @_
  );
  my $formula = $params{formula};
  my $formula_increment = $params{sample_rate}->() / $sample_rate;
  my $max = 2 ** $params{bits}->();
  my $t = 0;
  return sub {
    $t += $formula_increment;
    local $_ = int $t;
    return (((
      $formula->(int $t)
    ) % $max - ($max/2))/($max/2))
  }
}

 # Return RC low-pass filter output samples, given input samples,
 # time interval dt, and time constant RC
 # function lowpass(real[0..n] x, real dt, real RC)
   # var real[0..n] y
   # var real α = dt / (RC + dt)
   # y[0] := x[0]
   # for i from 1 to n
       # y[i] = α * x[i] + (1-α) * y[i-1]
       # OR y[i] = y[i-1] + α * (x[i] - y[i-1])
   # return y

sub lowpass {
  my %params = generalize( @_ );
  my $current_time = 0;
  my $last_out_sample = 0;
  sub {
    my $gen_sample = $params{gen}->();
    return undef if ! defined $gen_sample;
    # $current_time += $time_step;
    # my $alpha = $current_time / ($params{rc}->() + $current_time);
    my $alpha = $time_step / ($params{rc}->() + $time_step);
    my $sample = $last_out_sample + $alpha * ($gen_sample - $last_out_sample);
    $last_out_sample = $sample;
    return $sample;
  }
}


 # // Return RC high-pass filter output samples, given input samples,
 # // time interval dt, and time constant RC
 # function highpass(real[0..n] x, real dt, real RC)
   # var real[0..n] y
   # var real α := RC / (RC + dt)
   # y[0] := x[0]
   # for i from 1 to n
     # y[i] := α * y[i-1] + α * (x[i] - x[i-1])
   # return y

sub highpass {
  my %params = generalize( @_ );
  my $current_time = 0;
  my $last_sample = 0;
  my $last_out_sample = 0;
  sub {
    my $gen_sample = $params{gen}->();
    my $rc = $params{rc}->();
    $current_time += $time_step;
    my $alpha = $rc / ($rc + $current_time);
    my $sample = $alpha * $last_out_sample + $alpha * ($gen_sample - $last_sample);
    $last_out_sample = $sample;
    $last_sample = $gen_sample;
    return $sample;
  }
}


######################################
# Now let's pretend to be an object

use overload
  '+' => \&m_seq,
  '*' => \&m_combine,
  '""' => sub { },
;

sub new {
  my $class = shift;
  my $gen = shift;
  if(!ref $gen) {
    print STDERR "segement '$gen'\n";
    $gen = segment($gen);
  # } elsif(ref $gen eq 'CODE') {
    # $gen = formula($gen);
  }
  my $self = {
    gen => $gen,
  };
  bless $self, $class;
  return $self;
}

sub m_seq {
  my ($self, $other, $swap) = @_;
  my $s = sequence($self->{gen}, $other->{gen});
  return Audio::NoiseGen->new($s);
}

sub m_combine {
  my ($self, $other, $swap) = @_;
  print STDERR "combine!\n";
  my $s = combine($self->{gen}, $other->{gen});
  return Audio::NoiseGen->new($s);
}

sub G {
  my $x = shift;
  return Audio::NoiseGen->new($x);
}

sub mplay {
  my $self = shift;
  play($self->{gen});
}

# (
  # ( G('C C C') + G('E E E') )
  # * ( G('D') * G('E') * G('G') ) # chord
# )->mplay;

1;

