package Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume - Struct that stores
the relevant values for ID3v2 peak volume 

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume;
  
  my $i = Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume->new();
  $i->setBitsRepresentingPeak(20);
  print $i->bitsRepresentingPeak(), "\n"; # got 20
  $i->setPeakVolume(Audio::TagLib::ByteVector->new("1111"));
  print $i->peakVolume()->data(), "\n"; # got "1111"

=head1 DESCRIPTION

The peak volume is described as a series of bits that is padded to
fill a block of bytes. These two values should always be updated in
tandem. 

=over

=item I<new()>

Constructs an empty peak volume description.

=item I<UV bitsRepresentingPeak()>

Returns the number of bits (in the range of 0 to 255) used to describe
the peak volume.

=item I<void setBitsRepresentingPeak(UV $b)>

Sets the number of bits to $b, which is used to describe the peak
volume. 

=item I<L<ByteVector|Audio::TagLib::ByteVector> peakVolume()>

Returns the array of bits (represented as a series of bytes) used to
describe the peak volume.

=item I<void setPeakVolume(L<ByteVector|Audio::TagLib::ByteVector> $v)>

Sets the array of bits to $v, which is used ot describe the peak
volume. 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib>

=head1 AUTHOR

Dongxu Ma, E<lt>dongxu@cpan.orgE<gt>

=head1 MAINTAINER

Geoffrey Leach GLEACH@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010 by Dongxu Ma

Copyright (C) 2011 - 2013 Geoffrey Leach

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
