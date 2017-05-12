package Audio::Analyzer;

our $VERSION = '0.22';

use strict;
use warnings;

use Carp qw(croak);

use Math::FFT;

use constant DEFAULT_DFT_SIZE => 2 ** 11;
use constant DEFAULT_SAMPLE_RATE => 44100;
use constant DEFAULT_CHANNELS => 2;
use constant DEFAULT_BITS_PER_SAMPLE => 16;

#value can be undef if fileless operation is being used
use constant INPUT => 0;
use constant FILE_NAME => 1;
use constant DFT_SIZE => 2;
use constant SEEK_STEP => 3;
use constant READ_SIZE => 4;
use constant CHANNELS => 5;
use constant BYTES_PER_SAMPLE => 6;
use constant SAMPLE_RATE => 7;
use constant FFT => 8;
use constant FREQ_CACHE => 9;
use constant SCALER => 10;
use constant BYTES => 11;
use constant EOF_FOUND => 12;
use constant FILELESS_BUFFER => 13;

sub new {
	my ($class, %opts) = @_;

	my $self = [];

	bless($self, $class);

	$self->init(%opts);	

	return $self;
}

sub add_samples {
    my ($self, @samples) = @_;
    push(@{$self->[FILELESS_BUFFER]}, @samples);
    return;
}

sub sample_buffer_size {
    my ($self) = @_;
    return scalar(@{$self->[FILELESS_BUFFER]});
}

sub next {
	my ($self) = @_;
	my @samples;
	my $chunk;
	
	if (defined($self->[INPUT])) {
        my $pcm = $self->read_pcm;
        
        if (! defined($pcm)) {
            return undef;
        }
        
        @samples = $self->convert_pcm($pcm);
        
	} else {
	    @samples = $self->get_fileless_samples;
	    return undef unless @samples;
	}


	my $channels = $self->split_channels(@samples);

	$chunk = Audio::Analyzer::Chunk->new($self, $channels);

	return $chunk;
}

sub progress {
	my ($self) = @_;
	my $bytes = $self->[BYTES];
	my $input = $self->[INPUT];
	my $size = (stat($input))[7];

	return int($bytes / $size * 100);
}

sub freqs {
	my ($self) = @_;
	my $sample_rate = $self->[SAMPLE_RATE];
	my $dft_size = $self->[DFT_SIZE];
	my $freq_cache = $self->[FREQ_CACHE];
	my @freqs;

	if (defined($freq_cache)) {
		return $freq_cache;
	}

	for(my $i = 0; $i < $dft_size / 2; $i++) {
		$freqs[$i] = $i / $dft_size * $sample_rate;
	}

	$self->[FREQ_CACHE] = \@freqs;

	return $self->[FREQ_CACHE];
}

#private interface starts here

sub init {
	my ($self, %opts) = @_;
	my $file;
	my $dft_size;
	my $seek_step;
	my $channels;
	my $bits_per_sample;
	my $sample_rate;
	my $read_size;
	my $scaler;
	my $fps;

    if (exists($opts{'file'})) {
        if (! defined($file = $opts{'file'})) {
            croak "if the file option is given it must have a value";
        }
    } elsif (! defined $opts{fileless}) {
        croak "no file was specified and fileless operation is not configured";
    }

	if (! defined($dft_size = $opts{'dft_size'})) {
		$dft_size = DEFAULT_DFT_SIZE;
	}

	if (! defined($sample_rate = $opts{'sample_rate'})) {
		$sample_rate = DEFAULT_SAMPLE_RATE;
	}

	if (! defined($channels = $opts{'channels'})) {
		$channels = DEFAULT_CHANNELS;
	}

	if (defined($bits_per_sample = $opts{'bits_per_sample'})) {
		if ($bits_per_sample != 8 && $bits_per_sample != 16) {
			croak("bits_per_sample must be 8 or 16");
		}
	} else {
		$bits_per_sample = DEFAULT_BITS_PER_SAMPLE;
	}

	$read_size = $dft_size * $channels * $bits_per_sample / 8;

	if (defined($fps = $opts{'fps'})) {
	    croak "unable to use audio/visual sync with fileless operation"
	       unless defined $file; 
		$seek_step = $sample_rate / $fps * $bits_per_sample / 8 * $channels;	
	} elsif (defined $seek_step && ! defined $file) {
        croak "unable to use seek_step with fileless operation";
	} elsif (! defined($seek_step = $opts{'seek_step'})) {
		$seek_step = $read_size;
	}

    if (defined($file)) {
        if (ref($file) eq 'GLOB') {
            $self->[INPUT] = $file;
            $self->[FILE_NAME] = scalar($file); 
        } else {
            croak "could not open $file: $!" unless open(PCM, $file);
            
            $self->[INPUT] = \*PCM;
            $self->[FILE_NAME] = $file;
        }
    }

	$self->[BYTES_PER_SAMPLE] = $bits_per_sample / 8;
	$self->[CHANNELS] = $channels;
	$self->[SAMPLE_RATE] = $sample_rate;
	$self->[DFT_SIZE] = $dft_size;
	$self->[SEEK_STEP] = $seek_step;
	$self->[READ_SIZE] = $read_size;
	$self->[BYTES] = 0;
	$self->[EOF_FOUND] = 0;
	
	unless(defined($file)) {
	    $self->[FILELESS_BUFFER] = [];
	}

	if (! exists($opts{scaler})) {
		$scaler = Audio::Analyzer::ACurve->new($self);
	} elsif(defined($opts{scaler})) {
		my $requested = $opts{scaler};

		$scaler = $requested->new($self);
	}

	$self->[SCALER] = $scaler;

	return $self;
}

sub split_channels {
	my ($self, @samples) = @_;
	my $channels = $self->[CHANNELS];
	my @split;
	my $size = scalar(@samples);

	for(my $i = 0; $i < $size; $i++) {
		my $chan = int($i % $channels);
		push(@{$split[$chan]}, $samples[$i]);
	}

	return \@split;
}


#converts PCM into floating point representation
sub convert_pcm {
	my ($self, $pcm) = @_;
	my $bytes_per_sample = $self->[BYTES_PER_SAMPLE];
	my @samples;

	if ($bytes_per_sample == 2) {
		while(length($pcm) >= 2) {
			my $sample = unpack('s<', substr($pcm, 0, 2, ''));
			push(@samples, $sample);
		}
	} else {
		die "8 bit PCM isn't implemented yet";
	}

	return @samples;
}

sub get_fileless_samples {
    my ($self) = @_;
    my $input = $self->[INPUT];
    my $read_size = $self->[READ_SIZE];
    my $fileless_buffer = $self->[FILELESS_BUFFER];
    my $samples_needed = $read_size / $self->[BYTES_PER_SAMPLE];
    
    if (defined $input) {
        die "read_buffer() was called for fileless operation but there was an input file ref?";
    }

    return () unless scalar(@$fileless_buffer) >= $samples_needed;
    return splice(@$fileless_buffer, 0, $samples_needed);
}

sub read_pcm {
	my ($self) = @_;
	my $input = $self->[INPUT];
	my $read_size = $self->[READ_SIZE];
	my $seek_step = $self->[SEEK_STEP];
	my $bytes = $self->[BYTES];
	my $EOF_found = $self->[EOF_FOUND];
	my $buf;
	my $ret;
	my $rewind;
	
	die "there was no input filehandle ref" unless defined $input;
	
	$ret = read($input, $buf, $read_size);

	if (! defined($ret)) {
		die "could not read: $!";
	} elsif ($ret == 0) {
		return undef;
	} elsif ($ret < $read_size) {
		#hit the end and did not get enough data for the FFT - seek 
		#backwards a whole read_size and finish the last reading
		#as best as possible
		my $size = (stat($input))[7];
		
		$self->[EOF_FOUND] = 1;

		seek($input, $size - $read_size, 0) or die "could not seek: $!";

		return $self->read_pcm;
	}

	$bytes += $seek_step;

	$rewind = $read_size - $seek_step;

	if ($rewind && ! $EOF_found) {
		seek($input, $rewind * -1, 1) or die "could not seek: $!";
	}

	$self->[BYTES] = $bytes;

	return $buf;
}

sub scaler {
	my ($self) = @_;
	
	return $self->[SCALER];
}

package Audio::Analyzer::Chunk;

our $VERSION = '0.02';

use strict;
use warnings;

sub new {
	my ($class, $analyzer, $channels) = @_;
	my $self = {};

	$self->{analyzer} = $analyzer;
	$self->{channels} = $channels;

	bless($self, $class);

	return $self;
}

sub pcm {
	my ($self) = @_;

	return $self->{channels};
}

sub fft {
	my ($self) = @_;
	my $channels = $self->{channels};
	my @mags;

	for(my $i = 0; $i < scalar(@$channels); $i++) {
		$mags[$i] = $self->do_fft($channels->[$i]);
	}

	return \@mags;
}

sub rms {
	my $self = shift(@_);
	my $size = scalar(@_);
	my $sum;

	for(my $i = 0; $i < $size; $i++) {
		$sum += $_[$i] ** 2;
	}

	$sum /= $size;

	return sqrt($sum);
}

sub combine_fft {
	my ($self, $channels) = @_;
	my $num_channels = scalar(@$channels);
	my $length = scalar(@{$channels->[0]});
	my @new;

	for(my $i = 0; $i < $length; $i++) {
		my @row;

		for(my $j = 0; $j < $num_channels; $j++) {
			push(@row, $channels->[$j][$i]);	
		}

		$new[$i] = $self->rms(@row);
	}

	return \@new;
}

sub analyzer {
	my ($self) = @_;

	return $self->{analyzer};
}

#private methods

sub do_fft {
	my ($self, $samples) = @_;
	my $fft = Math::FFT->new($samples);
	my $coeff = $fft->rdft;
	my $size = scalar(@$coeff);
	my $k = 0;
	my @mag;

	$mag[$k] = sqrt($coeff->[$k*2]**2);

	for($k = 1; $k < $size / 2; $k++) {
		$mag[$k] = sqrt(($coeff->[$k * 2] ** 2) + ($coeff->[$k * 2 + 1] ** 2));
	}

	$self->scale(\@mag);

	return \@mag;
}

sub scale {
	my ($self, $mags) = @_;
	my $scaler = $self->analyzer->scaler;
	
	if (defined($scaler)) {
		$scaler->scale($mags);
	}
}

package Audio::Analyzer::ACurve;

our $VERSION = '0.02';

use strict;
use warnings;

use Carp; 
                      
use constant SCALE => 5000000; #tested by running some Prodigy 
			       #through the system

sub new {
	my ($class, $analyzer) = @_;
	my $self = {};

	$self->{analyzer} = $analyzer;

	if (! defined($analyzer)) {
		croak "I need an analyzer";
	}

	bless($self, $class);

	$self->init;

	return $self;
}

sub init {
	my ($self) = @_;
	my $analyzer = $self->{analyzer};
	my @correction;
	my $freqs = $analyzer->freqs;

	for(my $i = 0; $i < scalar(@$freqs); $i++) {
		my $freq = $freqs->[$i];
	
		if ($freq < 10000) {
			$correction[$i] = $self->solve_one_A($freq);
		} else {
			$correction[$i] = 1;
		}

	}

	$self->{correction} = \@correction;
}

sub solve_one_A {
	my ($self, $freq) = @_;
	my $term_1 = ($freq ** 2) + (20.6 ** 2);
	my $term_2 = ($freq ** 2) + (12200 ** 2);
	my $term_3 = sqrt(($freq ** 2) + (107.7 ** 2));
	my $term_4 = sqrt(($freq ** 2) + (737.9 ** 2));
	
	return (12200 ** 2) * ($freq ** 4) / ($term_1 * $term_2 * $term_3 * $term_4);
}

sub scale {
	my ($self, $mags) = @_;
	my $correction = $self->{correction};
	my $size = scalar(@$mags);	

	for(my $i = 0; $i < $size; $i++) {
		$mags->[$i] *= $correction->[$i];
		$mags->[$i] /= SCALE;

		if ($mags->[$i] > 1) {
			$mags->[$i] = 1;
		}
	}
}

package Audio::Analyzer::AutoScaler;

our $VERSION = '0.02';

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{peak} = 0;

	bless($self, $class);

	return $self;
}

sub scale {
	my ($self, $readings) = @_;
	my $size = scalar(@$readings);

	for(my $i = 0; $i < $size; $i++) {
		my $one = $readings->[$i];

		if ($one > $self->{peak}) {
			$self->{peak} = $one;
		}

		$one /= $self->{peak};

		$readings->[$i] = $one;
	}
}

1;

__END__

=head1 NAME

Audio::Analyzer - Makes using Math::FFT very easy for audio analysis 

=head1 SYNOPSIS

  use Audio::Analyzer;

  $source = \*FILEHANDLE;
  $source = 'input.pcm';

  $analyzer = Audio::Analyzer->new(file => $source);

  while(defined($chunk = $analyzer->next)) {
    my $done = $analyzer->progress;

    print "$done% completed\n";
  }

  #useful information
  $freqs = $analyzer->freqs; #returns array reference
  
=head1 DESCRIPTION

This module makes it easy to analyze audio files with the Fast Fourier 
Transform and sync the output of the FFT in time for visual representation.

=head1 REFERENCE

=over 4

=item $analyzer = Audio::Analyzer->new(%opts)

Create a new instance of Audio::Analyzer ready to analyze a file as specified
by %opts. The options available are:

=over 4

=item file

A required option; must be either a string which is a filename or a reference
to an already open filehandle. The format must be little endian linear coded
PCM using signed integers; this is the same format as a WAV file with the
header ripped off. 

=item dft_size

The size of the number of samples taken per channel for each iteration of next.
Default of 1024.

=item sample_rate

How many samples per second are in the PCM file. Default of 44100.

=item bits_per_sample

How many bits per sample in the PCM; must be 16. Default of 16.

=item channels

How many channels of audio is in the PCM; Default 2.

=item fps 

How many frames per second are going to be used for audio/visual sync. 
Overrides seek_step. No default.

=item seek_step 

How far to move forward every iteration. Overridden by fps. Default is not to do
additional seeking which will not create audio/visual synchronized output.

=item scaler

Use another scaler class besides the default Audio::Analyzer::ACurve; 
pass in either a string of the name of the class that will be scaling or undef
to perform no scaling at all. See below for information on writting your own
scaler classes. The currently available scalers are:

=over 4

=item Audio::Analyzer::ACurve

A scaling system that maps the output of the Fourier Transform onto an 
approximation of the human perception of volume for 20-10,000 hz. This
makes the most sense of the output of the Fourier Transform if you want
to do visual representations of what you are hearing.

=item Audio::Analyzer::AutoScaler

A scaling system which tracks the peak level and forces all numbers to be
between 0 and 1, with 1 being a magnitude of the peak level.

=back 

=back

=item $chunk = $analyzer->next;

Iterate once and return a new chunk; see below for information on 
Audio::Analyzer::Chunk.

=item $freqs = $analyzer->freqs;

Return an array reference of the frequency numbers that we analyze. This array
ref is the same size as the number of elements in each channel from $chunk->fft.


=item $completed = $analyzer->progress;

Return a number between 0 and 99 that represents in percent how far along in 
the file we have processed.

=back

=head1 CHUNK SYSTEM

Instances of Audio::Analyzer::Chunk represent a set of PCM from the file. 
Operations on instances of this class perform the FFT and access the PCM.

=over 4

=item $channels = $chunk->pcm;

Return an array ref of channels; each array value is an array ref which contains
the samples from the PCM converted to numbers between -1 and 1.

=item $channels = $chunk->fft;

Return an array ref of channels; each array value is an array ref which contains
the magnitudes from the Fast Fourier Transform. Numbers are between 0 and 1.

=item $combined = $chunk->combine_fft($channels);

Combine together 2 or more channels of FFT output into a single array ref. The
returned ref contains the RMS of each of the channel specific readings.

=back

=head1 SCALER CLASSES

The scaler classes are simple. The scaler will be created through new and a 
reference to the analyzer object is provided as an argument. The scaler class
must return a blessed instance of itself.

To perform scaling, Audio::Analyzer will periodically invoke the scale method
of the scaler class. This method must take an array reference which represents
the data returned by the FFT for one channel. The scaler modifies the data
inside the array reference and does not return any value. 

Your scaler class should also force all output to be between 0 and 1.

=head1 EXAMPLE MEDIA

The following pieces of media were done using Audio::Analyzer:

=over 4 

=item http://www.youtube.com/watch?v=W8Jk8rTP5lg

=item http://www.youtube.com/watch?v=6yTEUBgvxs4

Templatized PovRay scenes written out one file per frame then rendered
into images individually with a make file.

=item http://www.youtube.com/watch?v=bFp2zZlFgv4

Imager::Graph generated pngs of the output of Audio::Analyzer and the internal
state of a software beat detector.

=back

=head1 LIMITATIONS

In no way shape or form should this module be considered accurate or
correct enough for actual scientific analysis.

=head1 AUTHOR

This module was created and documented by Tyler Riddle E<lt>triddle@gmail.comE<gt>. 
Many thanks to Andrew Rodland who contributed greatly to getting as far as we 
got.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-audio-analyzer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio::Analyzer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head2 Known Bugs

=over 4

=item This module is still not passing tests on all types of hardware. See
http://cpantesters.org/distro/A/Audio-Analyzer.html for details on what is
and is not passing. 

=back

Copyright 2007 Tyler Riddle, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
