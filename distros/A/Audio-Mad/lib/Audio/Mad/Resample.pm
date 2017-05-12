package Audio::Mad::Resample;
1;
__END__

=head1 NAME
  
  Audio::Mad::Resample - Resampling routines for mad_fixed_t data
  
=head1 SYPNOSIS

  my $resample = new Audio::Mad::Resample (44100, 48000);
  my ($left, $right) = $resample->resample($d_left, $d_right);
  
  $resample->init(22050, 8000);
  if ($resample->mode() == 2) { print "no resampling needed" }
  
=head1 DESCRIPTION

  This module provides a means of changing the sampling rate
  of streams of mad_fixed_t data produced by the underlying
  library.
  
  The underlying module resamples the streams using a linear
  resampling method,  provided with the mad-0.14.2b 
  distribution.  (Thanks,  Rob)
  
=head1 METHODS

=over 4

=item * new ([oldrate, newrate])

  Creates a new resampling object,  and attempts to initialize it 
  to convert samples in oldrate to samples in newrate.  You can
  call the ->init method later to change the sampling ratios if
  necessary.
  
=item * init([oldrate, newrate])

  Reinitializes an Audio::Mad::Resample object to resample
  at a different ratio.  Returns undef on error,  1 if
  resampling is necessary,  and 2 if resampling won't be
  necessary.
  
=item * resample(left, [right])

  Returns a stream of mad_fixed_t samples after applying linear 
  resampling.  Will return either one or two channels depending
  on what was passed into it.
  
=item * mode

  Returns either 1,  for resampling necessary,  or 2,  for
  no resampling necessary.

=back
  
=head1 AUTHOR

  Mark McConnell <mischke@cpan.org>
  
=cut

  