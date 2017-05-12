# -*- mode: perl -*-
#
# $Id: Reader.pm,v 1.4 2002/08/21 14:48:27 tai Exp $
#

package Audio::SoundFile::Reader;

=head1 NAME

 Audio::SoundFile::Reader - Reader class for various sound formats

=head1 SYNOPSIS

 use IO::Seekable;
 use Audio::SoundFile;

 $reader = new Audio::SoundFile::Reader($source, \$header);

 $length = $reader->bread_raw(\$buffer, $wanted);
 $length = $reader->bread_pdl(\$buffer, $wanted);

 $reader->fseek(1024, SEEK_SET);
 $reader->fseek(1024, SEEK_CUR);
 $reader->fseek(1024, SEEK_END);

 $reader->close;

=head1 DESCRIPTION

This module provides an interface to read various sound formats
supported by libsndfile.

In addition to usual I/O interface, it provides direct interface
to create PDL object without making a copy of data in pure-Perl
space. This is an advantage on both speed and memory, and is a
recommended way to manipulate sound data.

Currently supported methods are:

=over 4

=item $reader = new Audio::SoundFile::Reader($source, \$header);

Constructor.
Returns input stream object that reads from given source.

Also assigns header information read from the source to passed
scalar reference.

=item $reader->close;

Closes input stream.
This object will be unusable after this method is called.

=item $offset = $reader->fseek($offset, $whence);

Moves next reading position to a point where specified by $offset
and $whence. Note $offset is not a length in bytes, but a number
of frames to skip (frame is a block of data containing data of
all channels at given moment).

Return value (which should be a new position in number of frames)
is currently unreliable.

=item $offset = $reader->bseek($offset, $whence);

Moves next reading position to a point where specified by $offset
and $whence. Note $offset is not a length in bytes, but a number
of blocks to skip (block is a bulk of data containing data of
single channel at given moment).

Return value (which should be a new position in number of blocks)
is currently unreliable.

=item $length = $reader->bread_raw(\$buffer, $wanted);

Reads $wanted blocks of data, and stores it to $buffer as
a Perl scalar. Content of $buffer is not guranteed on error.

Returns length of the data actually stored, or 0 (or lesser value) on error.

=item $length = $reader->bread_pdl(\$buffer, $wanted);

Reads $wanted blocks of data, and stores it to $buffer as
a PDL object. Content of $buffer is not guranteed on error.

Returns length of the data actually stored, or 0 (or lesser value) on error.

=back

=cut

use DynaLoader;

use strict;
use vars qw($VERSION @ISA);

$VERSION = (split(/\s+/, q$Revision 1.1$))[1] / 10;
@ISA     = qw(DynaLoader);

use PDL::Core;

bootstrap Audio::SoundFile::Reader $VERSION;

=head1 NOTES

If you mix bseek/bread and fseek/fread, things might get
confusing due to shift in internal offset - please do it
with your responsibility.

=head1 AUTHORS / CONTRIBUTORS

Taisuke Yamada E<lt>tai@imasy.or.jpE<gt>

=head1 COPYRIGHT

Copyright (C) 2001. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
