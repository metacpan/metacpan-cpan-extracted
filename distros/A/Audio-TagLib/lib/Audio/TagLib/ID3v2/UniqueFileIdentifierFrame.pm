package Audio::TagLib::ID3v2::UniqueFileIdentifierFrame;

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

Audio::TagLib::ID3v2::UniqueFileIdentifierFrame - An implementation of ID3v2
unique identifier frames 

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::UniqueFileIdentifierFrame;
  
  my $i = Audio::TagLib::ID3v2::UniqueFileIdentifierFrame->new(
    Audio::TagLib::ByteVector->new(""));
  $i->setOwner(Audio::TagLib::String->new("blah"));
  print $i->owner()->toCString(), "\n"; # got "blah"

=head1 DESCRIPTION

This is an implementation of ID3v2 unique file identifier frames. This
frame is used to identify the file in an arbitrary database identified
by the owner field.

=over

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Creates a uniqe file identifier frame based on $data.

=item I<new(L<String|Audio::TagLib::String> $owner,
L<ByteVector|Audio::TagLib::ByteVector> $id)>

Creates a unique file identifier frame with the owner $owner and the
identification $id.

=item I<L<String|Audio::TagLib::String> owner()>

Returns the owner for the frame; essentially this is the key for
 determining which identification scheme this key belongs to. This
 will usually either be an email address or URL for the person or tool
 used to create the unique identifier.

see I<setOwner()>

=item I<L<ByteVector|Audio::TagLib::ByteVector> identifier()>

Returns the unique identifier. Though sometimes this is a text string
it also may be binary data and as much should be assumed when handling
it. 

=item I<void setOwner(L<String|Audio::TagLib::String> $s)>

Sets the owner of the identification scheme to $s.

see I<owner()>

=item I<void setIdentifier(L<ByteVector|Audio::TagLib::ByteVector> $v)>

Sets the unique file identifier to $v.

see I<identifier()>

=item I<L<String|Audio::TagLib::String> toString()>

see L<Audio::TagLib::ID3v2::Frame::toString()|Audio::TagLib::ID3v2::Frame>

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
