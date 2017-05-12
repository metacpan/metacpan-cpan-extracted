package Audio::TagLib::MPEG::Header;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

## no critic (ProhibitPackageVars)
## no critic (ProhibitMixedCaseVars)
our %_Version = (
    "Version1"   => 0,
    "Version2"   => 1,
    "Version2_5" => 2,
);

our %_ChannelMode = (
    "Stereo"        => 0,
    "JointStereo"   => 1,
    "DualChannel"   => 2,
    "SingleChannel" => 3,
);

sub get_version { return \%_Version; }

sub channel_mode { return \%_ChannelMode; }

1;
__END__

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::MPEG::Header - An implementation of MP3 frame headers

=head1 SYNOPSIS

  use Audio::TagLib::MPEG::Header;
  
  my $i = Audio::TagLib::MPEG::Header->new($data);
  print $i->layer(), "\n"; # normally got 3

=head1 DESCRIPTION

This is an implementation of MPEG Layer III headers. The API follows
more or less the binary format of these headers. Refer to
F<http://www.mp3-tech.org/programmer/frame_header.html> 

=over

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Parses an MPEG header based on $data.

=item I<new(Header $h)>

Does a shallow copy of $h.

=item I<DESTROY()>

Destroys this Header instance.

=item I<BOOL isValid()>

Returns true if the frame is at least an appropriate size and has
 legal values.

=item %_Version

 our %_Version = (
    "Version1"   => 0,
    "Version2"   => 1,
    "Version2_5" => 2,
 );

Deprecated. See L<get_version()|get_version>

=item get_version

The MPEG Version. C<keys %{Audio::TagLib::MPEG::Header:get_version()}> lists all
available values used in Perl code.

=item I<PV version()>

Returns the MPEG Version of the header.

=item I<IV layer()>

Returns the layer version. This will be between the values 1-3. 

=item I<BOOL protectionEnabled()>

Returns true if the MPEG protection bit is enabled.

=item I<IV bitrate()>

Returns the bitrate encoded in the header.

=item I<IV samplePerFrame()>

Returns the number of frames per sample.

=item I<IV sampleRate()>

Returns the sample rate in Hz.

=item I<BOOL isPadded()>

Returns true if the frame is padded.

=item %_ChannelMode

 our %_Version = (
    "Version1"   => 0,
    "Version2"   => 1,
    "Version2_5" => 2,
 );

Deprecated. See L<channel_mode()|channel_mode>

There are a few combinations or one or two channel audio that are
 possible. C<keys %{Audio::TagLib::MPEG::Header::channel_mode()}> lists all
 available values used in Perl code.

=item I<PV channelMode()>

Returns the channel mode for this frame.

=item I<BOOL isCopyrighted()>

Returns true if the copyrighted bit is set.

=item I<BOOL isOriginal()>

Returns true if the "original" bit is set.

=item I<IV frameLength()>

Returns the frame length.

=item I<copy(Header $h)>

Makes a shallow copy of the header.

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
