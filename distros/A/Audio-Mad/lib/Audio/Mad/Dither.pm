package Audio::Mad::Dither;
1;
__END__

=head1 NAME

  Audio::Mad::Dither - Dithering routines for mad_fixed_t data
  
=head1 SYPNOSIS

  my $dither = new Audio::Mad::Dither (MAD_DITHER_S16_LE);
  my $s16le = $dither->dither($fixed_l, $fixed_r);
  
  $dither->init(MAD_DITHER_S24_BE);
  my $s24be = $dither->dither($fixed_l);
  
=head1 DESCRIPTION

  This module provides a means of dithering and converting
  streams of mad_fixed_t samples into a small variety of
  pcm sample streams.
  
  The underlying module converts the streams using the linear
  quantization method provided in the mad-0.14.2b
  distribution.  
  
=head1 METHODS

=over 4

=item * new ([type])

  Creates a new Audio::Mad::Dither object,  and returns a 
  handle to it.  You may provide an optional type parmater,
  corresponding to a MAD_DITHER constant,  or accept the 
  default of signed 16 bit little endian samples.
  
=item * init ([type])

  Reinitializes an Audio::Mad::Dither object into producing 
  a different type of pcm stream.
  
=item * dither (left, [right])

  Returns a formatted stream of pcm samples,  dithered from
  the mad_fixed_t streams of samples:  left,  and optionally
  right (mono streams only have left channel).  The data
  returned here is appropriate to be sent to at a /dev/dsp
  or similar device.
  
=back

=head1 AUTHOR

  Mark McConnell <mischke@cpan.org>
  
=cut
