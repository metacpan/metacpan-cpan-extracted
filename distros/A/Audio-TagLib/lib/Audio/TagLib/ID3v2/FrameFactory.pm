package Audio::TagLib::ID3v2::FrameFactory;

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

Audio::TagLib::ID3v2::FrameFactory - A factory for creating ID3v2 frames

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::FrameFactory;
  
  my $i = Audio::TagLib::ID3v2::FrameFactory->instance();
  $i->setDefaultTextEncoding("UTF8");
  print $i->defaultTextEncoding(), "\n"; # got "UTF8"

=head1 DESCRIPTION

This factory abstracts away the frame creation process and
instantiates the appropriate ID3v2::Frame subclasses based on the
contents of the data.

Reimplementing this factory is the key to adding support for frame
types not directly supported by Audio::TagLib to your application. To do so
you would subclass this factory reimplement createFrame(). Then by
setting your factory to be the default factory in ID3v2::Tag
constructor or with MPEG::File::setID3v2FrameFactory() you can
implement behavior that will allow for new ID3v2::Frame subclasses
(also provided by you) to be used. 

This implements both I<abstract factory> and I<singleton> patterns of
which more information is available on the web and in software design
textbooks (Notably I<Design Patterns>).

=over

=item I<FrameFactory instance()> [static]

Returns an instance of FrameFactory.
As the constructor for FrameFactory is protected, this is the only method that
provides a FrameFactory for use in accessing other FrameFactory methods.

=item I<L<Frame|Audio::TagLib::ID3v2::Frame>
createFrame(L<Bytevector|Audio::TagLib::ByteVector> $data, BOOL
$synchSafeInts)> 

Create a frame based on $data. $synchSafeInts should only be set false
if we are parsing an old tag (v2.3 or older) that does not support
synchsafe ints.

Deprecated. Please use the method below that accepts an ID3v2::Header


=item I<L<Frame|Audio::TagLib::ID3v2::Frame>
createFrame(L<ByteVector|Audio::TagLib::ByteVector> $data, UV $version = 4)> 

Create a frame based on $data. $version should indicate the ID3v2
version of the tag. As ID3v2.4 is the most current version of the
standard 4 is the default.

Deprecated. Please use the method below that accepts an ID3v2::Header

=item I<L<Frame|Audio::TagLib::ID3v2::Frame>
createFrame(L<ByteVector|Audio::TagLib::ByteVector> $data, L<Headerr|Audio::TagLib::ID3v2::Header>
$tagHeader)>

Create a frame based on $data.  $tagHeader should be a valid ID3v2::Header instance.

=item I<PV defaultTextEncoding()>

Returns the default text encoding for text frames. If
setTextEncoding() has not been explicitly called this will only be
used for new text frames. However, if this value has been set
explicitly all frames will be converted to this type (unless it's
explitly set differently for the individual frame) when being
rendered. 

see I<setDefaultTextEncoding()>

=item I<void setDefaultTextEncoding(PV $encoding)>

Set the default text encoding for all text frames that are created to
$encoding. If no value is set the frames with either default to the
encoding type that was parsed and new frames default to Latin1.

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
