package Audio::TagLib::FLAC::Properties;

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

Audio::TagLib::FLAC::Properties - An implementation of audio property reading
for FLAC 

=head1 SYNOPSIS

  use Audio::TagLib::FLAC::Properties;
  
  my $i = Audio::TagLib::FLAC::Properties->new("sample file.flac");
  print $i->channels(); # should be 2 usually

=head1 DESCRIPTION

This reads the data from an FLAC stream found in the AudioProperties
API. 

=over

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data, IV $streamLength,
L<PV|Audio::TagLib::AudioProperties> $style = "Average")>

Create an instance of FLAC::Properties with the data read from the
ByteVector $data.

=item I<new(L<File|Audio::TagLib::FLAC::File> $file,
L<PV|Audio::TagLib::AudioProperties> $style = "Average")>

Create an instance of FLAC::Properties with the data read from the
FLAC::File $file.

=item I<DESTROY()>

Destroys this FLAC::Properties instance.

=item I<IV length()>

=item I<IV bitrate()>

=item I<IV sampleRate()>

=item I<IV channels()>

see L<AudioProperties|Audio::TagLib::AudioProperties>

=item I<sampleWidth()>

Returns the sample width as read from the FLAC identification header. 

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
