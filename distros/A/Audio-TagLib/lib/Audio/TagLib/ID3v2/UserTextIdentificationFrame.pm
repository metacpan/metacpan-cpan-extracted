package Audio::TagLib::ID3v2::UserTextIdentificationFrame;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::ID3v2::TextIdentificationFrame);

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v2::UserTextIdentificationFrame - An ID3v2 custom text
identification frame implementation

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::UserTextIdentificationFrame;
  
  my $i = Audio::TagLib::ID3v2::UserTextIdentificationFrame->new("Latin1");
  $i->setDescription(Audio::TagLib::String->new("blah blah"));
  print $i->description()->toCString(), "\n"; # got "blah blah"

=head1 DESCRIPTION

This is a specialization of text identification frames that allows for
user defined entries. Each entry has a description in addition to the
normal list of fields that a text identification frame has. 

This description identifies the frame and must be unique.

=over

=item I<new(PV $encoding = "Latin1")>

Constructs an empty user defined text identification frame. For this
to be a useful frame both a description and text must be set.

=item I<new(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Creates a frame based on $data.

=item I<L<String|Audio::TagLib::String> description()>

Returns the description for this frame.

=item I<void setDescription(L<String|Audio::TagLib::String> $s)>

Sets the description of the frame to $s. $s must be unique. You can
 check for the presense of another user defined text frame of the same
 type using find() and testing for null.

=item I<L<StringList|Audio::TagLib::StringList> fieldList()>

=item I<void setText(L<String|Audio::TagLib::String> $text)>

=item I<void setText(L<StringList|Audio::TagLib::StringList> $fields)>

see
L<Audio::TagLib::ID3v2::TextIdentificationFrame|Audio::TagLib::ID3v2::TextIdentificationFrame> 

=item I<UserTextIdentificationFrame find(L<Tag|Audio::TagLib::ID3v2::Tag>
$tag, L<String|Audio::TagLib::String> $description)> [static]

Searches for the user defined text frame with the description
$description in $tag. This returns undef if no matching frame were
found. 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<TextIdentificationFrame|Audio::TagLib::ID3v2::TextIdentificationFrame>

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
