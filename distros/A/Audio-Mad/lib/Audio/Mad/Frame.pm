package Audio::Mad::Frame;
1;
__END__

=head1 NAME

 Audio::Mad::Frame - Interface to mad_frame structure
 
=head1 SYPNOSIS

 my $frame = new Audio::Mad::Frame;

 FRAME: while(1) {
 	if ($frame->decode($stream) == -1) {
 		print "stream error: " . $stream->error() . "\n";
 		last FRAME;
 	}
 	
 	my $layer      = $frame->layer();
 	my $mode       = $frame->mode();
 	my $bitrate    = $frame->bitrate();
 	my $samplerate = $frame->samplerate();
 	my $timer      = $frame->duration(); #see Audio::Mad::Timer
 	my $flags      = $frame->flags();
 	
 	# do something with the frame.  usually requires
 	# Audio::Mad::Synth (see docs)
 }
 	
=head1 DESCRIPTION

  This package provides an interface to the underlying mad_frame
  structure used in the decoder library.  Most of the functions
  and underlying data are exposed to perl.
  
=head1 METHODS

=over 4

=item * new

  Allocates and initializes a new mad_frame structure,  and
  provides us with a handle to access it.
  
=item * decode(stream)

  Fully decodes the next available frame from 'stream' and 
  stores the information in it's internal structure.

=item * decode_header(stream)

  Much the same as 'decode' but it only decodes the header
  information from the next frame.  You can access the
  frame data at this point,  however,  the frame is not
  ready for synthesizing (or a ->mute call).  To finish 
  the decoding,  just call ->decode() again on the stream;
  although it's not required (e.g., you can seek/quit/etc)
  
=item * mute

  Mutes all the sub-band samples in the current frame
  structure.  It's usually prudent to call this after
  seeking around on a stream,  to avoid hearing
  scratches and pops.
  
=item * layer

=item * mode

=item * flags

=item * bitrate

=item * samplerate

  These functions retrieve the information from the currently 
  decoded frame header.  layer,  mode,  and flags correspond
  to the MAD_LAYER_, MAD_MODE_, and MAD_FLAG_ constants.
  bitrate and samplerate are represented as integers.
  
=item * duration

  Returns the duration of the currently decoded frame as an
  Audio::Mad::Timer object.  See Audio::Mad::Timer's manpage
  for details on what this means.
  
=item * NCHANNELS

  Returns number of channels in current frame.  1 or 2.
  
=item * NSBSAMPLES

  Returns number of samples in this frame.

=back

=head1 AUTHOR

  Mark McConnell <mischke@cpan.org>
  
=cut  	
