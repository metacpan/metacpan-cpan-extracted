package Algorithm::GDiffDelta;
use warnings;
use strict;

our $VERSION = '0.01';

require Exporter;
require DynaLoader;
our @ISA = qw( Exporter DynaLoader );
our @EXPORT_OK = qw( gdiff_adler32 gdiff_delta gdiff_apply );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

bootstrap Algorithm::GDiffDelta;

1;

__END__

=head1 NAME

Algorithm::GDiffDelta - generate and apply GDIFF format binary deltas

=head1 SYNOPSIS

    use Algorithm::GDiffDelta qw(
        gdiff_adler32 gdiff_delta gdiff_apply
    );

    # Pass in two file handles for reading from and one to
    # writing the GDIFF binary delta to:
    gdiff_delta($orig, $changed, $delta);

    # Pass in file handles of original file and GDIFF delta
    # to read from, and file to write reconstructed changed
    # file to:
    gdiff_apply($orig, $delta, $changed);

    # A fast adler32 digest implementation is also available:
    my $adler32 = gdiff_adler32(1, 'some data');
    $adler32 = gdiff_adler32($adler32, 'some more data');

=head1 DESCRIPTION

This module can be used to generate binary deltas describing the
differences between two files.  Given the first file and the
delta the second file can be reconstructed.

A delta is equivalent to the output of the unix C<diff> program,
except that it can efficiently represent the differences between
similar binary files, containing any sequences of bytes.  These
deltas can be used for updating files over a network (as C<rsync>
does) or for efficiently storing a revision history of changes to
a file (as Subversion does).

There are several formats used for binary deltas.  The one supported
by this module is the GDIFF format, which is fairly simple and is
documented as a W3C note (See the SEE ALSO section below).

This module generates and processes deltas using file handles.
It supports both native Perl file handles (created with the built-in
C<open> format) and objects that support the right methods.
For an object to work it must support at least the C<read>, C<seek>,
and C<tell> methods (if it is an input file) or the C<write> method
(if it is an output file).  This allows strings to be used for input
and output, by wrapping them in an L<IO::Scalar|IO::Scalar> object
or similar.  A future version of this module might support reading
and writing directly through references to scalars, because that
should be much more efficient.

See the section ALGORITHM AND DELTA FORMAT below for some notes on
the algorithm used by this module and how the GDIFF delta format works.

=head1 FUNCTIONS

No functions are exported by default.  Pass the function names to
Exporter in the C<use> line, or use the C<:all> tag to import them all.

=over 4

=item gdiff_adler32(I<$initial_value>, I<$string_data>)

Generate an Adler32 digest of the bytes in I<$string_data>, starting
with a hash value of I<$initial_value>.  This function is provided
only because it is used internally and so it might as well be made
available.  It isn't needed for generating or applying binary delta files.

The I<$initial_value> should usually be 1.  The result of calling this
function (which is a 32-bit unsigned integer value) can be passed back
in as a new initial value to checksum some more data.  This allows a
large file to be checksummed in separate chunks.

Another implementation of Adler-32 is provided in the
L<Digest::Adler32|Digest::Adler32> module.

The Adler-32 checksum algorithm is defined in RFC 1950, section 8.2.
Sample code in C is also provided there.

=item gdiff_apply(I<$file1>, I<$file2>, I<$delta_file>)

Takes three file handles.  The first two are read from, and it must
be possible to seek in them.  The third is written to.

This generates a binary delta describing the changes from I<$file1>
to I<$file2>.  The delta will allow I<$file2> to be reconstructed
from I<$file1> later.

No value is returned.  Errors will cause this function to croak
with a suitable error message.

=item gdiff_delta(I<$file1>, I<$delta_file>, I<$file2>)

Takes three file handles.  The first two are read from, and it must
be possible to seek in them.  The third is written to.

The delta is used to reconstruct I<$file2> from I<$file1>.
The delta must be a valid GDIFF file.

No value is returned.  Errors will cause this function to croak
with a suitable error message.

=back

=head1 ALGORITHM AND DELTA FORMAT

The algorithm and some of the code used in this module was derived
from the xdiff library.  It has been adjusted to write GDIFF deltas,
rather than the custom format used by xdiff (which was funtionally
equivalent but a little simpler than GDIFF).

Notes about how the algorithm works should be added here once I
figure it out myself.

A GDIFF file consists of a five byte header, followed by a sequence
of commands.  Each command has a one byte 'opcode' followed by some
arguments.  The delta file is terminated by opcode zero.

There are two types of commands.  DATA commands have a chunk of literal
data as one of their arguments, which is inserted into the output.
COPY commands cause a chunk of data from the input file to be
inserted into the output.

A GDIFF delta is one-way: if it generates I<$file2> from I<$file1>
then it cannot be used to generate I<$file1> from I<$file2>.

=head1 SEE ALSO

The xdiff library, upon which this module was based:
http://www.xmailserver.org/xdiff-lib.html

GDIFF specification (as a W3C note):
http://www.w3.org/TR/NOTE-gdiff-19970901

RFC 1950, which defines the Adler-32 checksum algorithm:
http://www.faqs.org/rfcs/rfc1950.html

=head1 AUTHOR AND COPYRIGHT

Parts of this library were derived from the code for libxdiff, by
Davide Libenzi E<lt>davidel@xmailserver.orgE<gt>

The rest is Copyright 2004, Geoff Richards E<lt>qef@laxan.comE<gt>

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or (at
your option) any later version. A copy of the license is available at:
http://www.gnu.org/copyleft/lesser.html

=cut

# vi:ts=4 sw=4 expandtab:
