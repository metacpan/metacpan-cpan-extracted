package Audio::Mad::Synth;
1;
__END__

=head1 NAME
  
  Audio::Mad::Synth - Interface to mad_synth structure
  
=head1 SYPNOSIS

  my $synth = new Audio::Mad::Synth;
  $synth->synth($frame);
  
  my ($left, $right) = $synth->samples();
  
  $synth->mute();
  
=head1 DESCRIPTION

  This package provides an interface to the underlying mad_synth
  structure used in the decoder library.  
  
=head1 METHODS

=over 4

=item * synth(frame)

  Takes the subband samples stored in frame and synthesizes pcm
  data from them.  
  
=item * samples

  Returns the current frames pcm samples in two scalars;  left 
  and right.  right will be 'undef' while decoding mono streams.
  
=item * mute

  Mutes the current stream of pcm samples in the synthesizer.
  
=back

=head1 AUTHOR

  Mark McConnell <mischke@cpan.org>
  
=cut
