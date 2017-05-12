package Audio::TagLib::File;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

## no critic (ProhibitMixedCaseVars)
## no critic (ProhibitPackageVars)
our %_Position = (
    "Beginning" => 0,
    "Current"   => 1,
    "End"       => 2,
);

sub position { return \%_Position; }

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::File -  A file class with some useful methods for tag
manipulation 

=head1 DESCRIPTION

This class is a basic file class with some methods that are
particularly useful for tag editors.  It has methods to take advantage
of ByteVector and a binary search method for finding patterns in a
file. 

=over

=item I<DESTROY()>

Destroys this File instance.

=item I<PV name()>

Returns the file name in the local file system encoding.

=item I<L<Tag|Audio::TagLib::Tag> tag()> [pure virtual]

Returns this file's tag. This should be reimplemented in the concrete
subclasses. 

=item I<L<AudioProperties|Audio::TagLib::AudioProperties> audioProperties()>
[pure virtual]

Returns this file's audio properties.  This should be reimplemented in
the concrete subclasses. If no audio properties were read then this
will return undef.

=item I<BOOL save()> [pure virtual]

Save the file and its associated tags.  This should be reimplemented
  in the concrete subclasses.  Returns true if the save succeeds.

=item I<L<ByteVector|Audio::TagLib::ByteVector> readBlock(UV $length)>

Reads a block of size $length at the current get pointer.

=item I<void writeBlock(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Attempts to write the block $data at the current get pointer.  If the
file is currently only opened read only -- i.e. readOnly() returns
true -- this attempts to reopen the file in read/write mode.

=item I<IV find(L<ByteVector|Audio::TagLib::ByteVector> $pattern, IV
$fromOffset = 0, L<ByteVector|Audio::TagLib::ByteVector> $before =
L<ByteVector::null|Audio::TagLib::ByteVector>)>

Returns the offset in the file that $pattern occurs at or -1 if it can
  not be found. If $before is set, the search will only continue until
  the pattern $before is found. This is useful for tagging purposes to
  search for a tag before the synch frame.

Searching starts at $fromOffset, which defaults to the beginning of
  the file.

This has the practial limitation that $pattern can not be longer
  than the buffer size used by readBlock().  Currently this is 1024
  bytes. 

=item I<IV rfind(L<ByteVector|Audio::TagLib::ByteVector> $pattern, IV
$fromOffset = 0, L<ByteVector|Audio::TagLib::ByteVector> $before =
L<ByteVector::null|Audio::TagLib::ByteVector>)>

Returns the offset in the file that $pattern at or -1 if it can not be
found. If $before is set, the search will only continue until the
pattern $before is found. This is useful for tagging purposes to
search for a tag before the synch frame.

Searching starts at $fromOffset and proceeds from the that point to
the beginning of the file and defaults to the end of the file.

This has the practial limitation that $pattern can not be longer
than the buffer size used by readBlock().  Currently this is 1024
bytes.

=item I<void insert(L<ByteVector|Audio::TagLib::ByteVector> $data, UV $start
= 0, UV $replace = 0)>

Insert $data at position $start in the file overwriting $replace bytes
of the original content.

This method is slow since it requires rewriting all of the file after
  the insertion point.

=item I<void removeBlock(UV $start = 0, UV $length = 0)>

Removes a block of the file starting a $start and continuing for
$length bytes.

This method is slow since it involves rewriting all of the file after
the removed portion.

=item I<BOOL readOnly()>

Returns true if the file is read only (or if the file can not be
opened). 

=item I<BOOL isOpen()>

Since the file can currently only be opened as an argument to the
constructor (sort-of by design), this returns if that open succeeded.

=item I<BOOL isValid()>

Returns true if the file is open and readble and valid information for
  the  Tag and / or AudioProperties was found.

=item I<void seek(IV $offset, L<PV|Audio::TagLib::File> $p = "Beginning")>

Move the I/O pointer to $offset in the file from position $p. This
defaults to seeking from the beginning of the file.

=item I<void clear()>

Reset the end-of-file and error flags on the file.

=item I<IV tell()>

Returns the current offset withing the file.

=item I<IV length()>

Returns the length of the file.

=item I<BOOL isReadable(PV $file)> [static]

Returns true if $file can be opened for reading.  If the file does not
exist, this will return false.

=item I<BOOL isWritable(PV $file)> [static]

Returns true if $file can be opened for writing.

=item %_Position

Depreciated. See position()

=item position

  Position in the file used for seeking. C<keys
  %Audio::TagLib::File::position()> returns a reference to an hash 
  that lists all positioning codes.

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
