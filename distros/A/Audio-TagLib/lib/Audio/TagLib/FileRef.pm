package Audio::TagLib::FileRef;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use overload
    q(==) => \&_equal,
    q(!=) => sub { not shift->_equal(@_); };

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::FileRef - This class provides a simple abstraction for
creating and handling files 

=head1 SYNOPSIS

  use Audio::TagLib::FileRef;
  
  my $i = Audio::TagLib::FileRef->new("sample file.mp3");
  $i->tag()->setTitle(Audio::TagLib::String->new("sample title"));
  print $i->tag()->toCString(), "\n"; # got "sample title"

=head1 DESCRIPTION

FileRef exists to provide a minimal, generic and value-based wrapper
around a File.  It is lightweight and implicitly shared, and as such
suitable for pass-by-value use.  This hides some of the uglier details
of L<Audio::TagLib::File|Audio::TagLib::File> and the non-generic portions of the
concrete file implementations. 

This class is useful in a "simple usage" situation where it is
desirable to be able to get and set some of the tag information that
is similar across file types.

Also note that it is probably a good idea to plug this into your mime
type system rather than using the constructor that accepts a file name
using the FileTypeResolver.

see L<FileTypeResolver|Audio::TagLib::FileRef::FileTypeResolver>

see I<addFileTypeResolver()>

=over

=item I<new()>

Creates a null FileRef.

=item I<new(PV $fileName, BOOL $readAudioProperties = TRUE
L<PV|Audio::TagLib::AudioProperties> $audioPropertiesStyle = "Average")>

Create a FileRef from $fileName. If $readAudioProperties is true then
the audio properties will be read using $audioPropertiesStyle. If
$readAudioProperties is false then $audioPropertiesStyle will be
ignored. 

Also see the note in the class documentation about why you may not
want to use this method in your application.

=item I<new(PV $file)>

construct a FileRef using $file.  The FileRef now takes ownership of
the pointer and will delete the File when it passes out of scope.

=item I<new(L<FileRef|Audio::TagLib::FileRef> $ref)>

Make a copy of $ref.

=item I<DESTROY()>

Destroys this FileRef instance.

=item I<L<Tag|Audio::TagLib::Tag> tag()>

Returns the file's tag.

B<WARNING> This pointer will become invalid when this FileRef and all
copies pass out of scope.

see I<File::tag()>

=item I<L<AudioProperties|Audio::TagLib::AudioProperties> audioProperties()>

Returns the audio properties for this FileRef. If no audio properties
were read then this will return undef.

=item I<L<File|Audio::TagLib::File> file()>

Returns the file represented by this handler class.

As a general rule this call should be avoided since if you need to
work with file objects directly, you are probably better served
instantiating the File subclasses (i.e. MPEG::File) manually and
working with their APIs. 

This I<handle> exists to provide a minimal, generic and value-based
wrapper around a File.  Accessing the file directly generally
indicates a moving away from this simplicity (and into things beyond
the scope of FileRef).

B<WARNING> This pointer will become invalid when this FileRef and all
copies pass out of scope.

=item I<BOOL save()>

Saves the file. Returns true on success.

=item I<L<FileTypeResolver|Audio::TagLib::FileRef::FileTypeResolver>
addFileTypeResolver(L<FileTypeResolver|Audio::TagLib::FileRef::FileTypeResolver>
$resolver)> [static]

Adds a FileTypeResolver to the list of those used by Audio::TagLib.  Each
additional FileTypeResolver is added to the front of a list of
resolvers that are tried.  If the FileTypeResolver returns zero the
next resolver is tried.

Returns the added resolver (the same one that's passed in -- this is
mostly so that static inialializers have something to use for
assignment). 

see L<FileTypeResolver|Audio::TagLib::FileRef::FileTypeResolver>

=item I<L<StringList|Audio::TagLib::StringList> defaultFileExtensions()>
[static] 

As is mentioned elsewhere in this class's documentation, the default
file type resolution code provided by Audio::TagLib only works by comparing
  file extensions.

This method returns the list of file extensions that are used by
  default.

The extensions are all returned in lowercase, though the comparison
  used by Audio::TagLib for resolution is case-insensitive.

B<NOTE> This does not account for any additional file type resolvers
  that are plugged in.  Also note that this is not intended to replace
  a propper mime-type resolution system, but is just here for
  reference. 

see L<FileTypeResolver|Audio::TagLib::FileRef::FileTypeResolver>

=item I<BOOL isNull()>

Returns true if the file (and as such other pointers) are null.

=item I<L<File|Audio::TagLib::File> create(PV $fileName, BOOL
$readAudioProperties = TRUE, L<PV|Audio::TagLib::AudioProperties>
$audioPropertiesStyle = "Average")> [static]

A simple implementation of file type guessing. If $readAudioProperties
  is true then the audio properties will be read using
  $audioPropertiesStyle. If $readAudioProperties is false then
  $audioPropertiesStyle will be ignored.

B<NOTE> You generally shouldn't use this method, but instead the
constructor directly.

=back

=head2 OVERLOADED OPERATORS

B<== !=>

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
