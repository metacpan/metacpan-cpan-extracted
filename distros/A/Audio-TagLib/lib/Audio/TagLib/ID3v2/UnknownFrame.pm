package Audio::TagLib::ID3v2::UnknownFrame;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::ID3v2::Frame);

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::UnknownFrame - A frame type unkown to Audio::TagLib

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::UnknownFrame;
  
  my $i = Audio::TagLib::ID3v2::UnknownFrame->new(
    Audio::TagLib::ByteVector->new("blah"));
  print $i->data()->data(), "\n"; # got "blah"

=head1 DESCRIPTION

This class represents a frame type not known (or more often simply
unimplemented) in Audio::TagLib. This is here provide a basic API for
manipulating the binary data of unknown frames and to provide a means
of rendering such unknown frames.

Please note that a cleaner way of handling frame types that Audio::TagLib
does not understand is to subclass ID3v2::Frame and
ID3v2::FrameFactory to have your frame type supported through the
standard ID3v2 mechanism. 

=over

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Constructs an unknown frame based on $data.

=item I<DESTROY()>

Destroys the instance.

=item I<L<String|Audio::TagLib::String> toString()>

see L<Audio::TagLib::ID3v2::Frame::toString()|Audio::TagLib::ID3v2::Frame>

=item I<L<ByteVector|Audio::TagLib::ByteVector> data()>

Returns the field data (everything but the header) for this frame. 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<Frame|Audio::TagLib::ID3v2::Frame>

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
