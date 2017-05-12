package Audio::TagLib::MPEG::Properties;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::AudioProperties);

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::MPEG::Properties - An implementation of audio property reading
for MP3 

=head1 SYNOPSIS

  use Audio::TagLib::MPEG::Properties;
  
  my $f = Audio::TagLib::MPEG::File->new("sample file.mp3");
  my $i = $f->audioProperties();
  print $i->layer(), "\n"; # got 3

=head1 DESCRIPTION

This reads the data from an MPEG Layer III stream found in the
AudioProperties API. 

=over

=item I<new(PV $file, PV $style = "Average")>

Create an instance of MPEG::Properties with the data read from the
MPEG::File $file.

=item I<DESTROY()>

Destroys this MPEG Properties instance.

=item I<IV length()>

=item I<IV bitrate()>

=item I<IV sampleRate()>

=item I<IV channels()>

see L<AudioProperties|Audio::TagLib::AudioProperties>

=item I<PV version()>

Returns the MPEG Version of the file.

see L<Audio::TagLib::MPEG::Header|Audio::TagLib::MPEG::Header>

=item I<IV layer()>

Returns the layer version. This will be between the values 1-3.

=item I<BOOL protectionEnabled()>

Returns true if the MPEG protection bit is enabled.

=item I<PV channelMode()>

Returns the channel mode for this frame.

see L<Audio::TagLib::MPEG::Header|Audio::TagLib::MPEG::Header> 

=item I<BOOL isCopyrighted()>

Returns true if the copyrighted bit is set.

=item I<BOOL isOriginal()>

Returns true if the "original" bit is set.


=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<AudioProperties|Audio::TagLib::AudioProperties>

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
