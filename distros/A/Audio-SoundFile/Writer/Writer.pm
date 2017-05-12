# -*- mode: perl -*-
#
# $Id: Writer.pm,v 1.3 2002/08/21 14:48:53 tai Exp $
#

package Audio::SoundFile::Writer;

=head1 NAME

 Audio::SoundFile::Writer - Writer class for various sound formats

=head1 SYNOPSIS

 use Audio::SoundFile;
 use Audio::SoundFile::Header;

 $header = new Audio::SoundFile::Header(...);
 $writer = new Audio::SoundFile::Writer($target, $header);

 $length = $writer->bwrite_raw($buffer);
 $length = $writer->bwrite_pdl($buffer);

 $writer->fseek(1024, SEEK_SET); # seek by frame
 $writer->fseek(1024, SEEK_CUR); # seek by frame
 $writer->fseek(1024, SEEK_END); # seek by frame

 $writer->bseek(1024, SEEK_SET); # seek by block
 $writer->bseek(1024, SEEK_CUR); # seek by block
 $writer->bseek(1024, SEEK_END); # seek by block

 $writer->close;

=head1 DESCRIPTION

This module provides an interface to write various sound formats
supported by libsndfile.

In addition to usual I/O interface, it provides direct interface
to write PDL object without making a copy of data in pure-Perl
space. This is an advantage on both speed and memory, and is a
recommended way to handle sound data.

Currently supported methods are:

=over 4

=item $writer = new Audio::SoundFile::Writer($target, $header);

Constructor.
Returns output stream object that writes to given target
in a format specified by $header.

=item $writer->close;

Closes output stream.
This object will be unusable after this method is called.

=item $offset = $writer->fseek($offset, $whence);

Moves next writing position to a point where specified by $offset
and $whence. Note $offset is not a length in bytes, but a number
of frames to skip (frame is a block of data containing data of
all channels at given moment).

Return value (which should be a new position in number of frames)
is currently unreliable.

=item $offset = $writer->bseek($offset, $whence);

Moves next writing position to a point where specified by $offset
and $whence. Note $offset is not a length in bytes, but a number
of blocks to skip (block is a bulk of data containing data of
one channel at given moment).

Return value (which should be a new position in number of blocks)
is currently unreliable.

=item $length = $write->bwrite_raw($buffer, $wanted);

Writes $wanted blocks of data from $buffer, which should be
a Perl scalar.

Returns length of the data actually written, or -1 on error.

=item $length = $reader->bwrite_pdl($buffer, $wanted);

Writes $wanted blocks of data from $buffer, which should be
a PDL object.

Returns length of the data actually written, or -1 on error.

=back

=cut

use DynaLoader;

use strict;
use vars qw($VERSION @ISA);

$VERSION = (split(/\s+/, q$Revision 1.1$))[1] / 10;
@ISA     = qw(DynaLoader);

bootstrap Audio::SoundFile::Writer $VERSION;

=head1 NOTES

If you mix bseek/bwrite and fseek/fwrite, things might get
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
