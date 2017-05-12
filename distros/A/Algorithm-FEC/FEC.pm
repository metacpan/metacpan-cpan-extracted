=head1 NAME

Algorithm::FEC - Forward Error Correction using Vandermonde Matrices

=head1 SYNOPSIS

 use Algorithm::FEC;

=head1 DESCRIPTION

This module is an interface to the fec library by Luigi Rizzo et al., see
the file README.fec in the distribution for more details.

This library implements a simple (C<encoded_blocks>,C<data_blocks>)
erasure code based on Vandermonde matrices.  The encoder takes
C<data_blocks> blocks of size C<block_size> each, and is able to produce
up to C<encoded_blocks> different encoded blocks, numbered from C<0>
to C<encoded_blocks-1>, such that any subset of C<data_blocks> members
permits reconstruction of the original data.

Allowed values for C<data_blocks> and C<encoded_blocks> must obey the
following equation:

   data_blocks <= encoded_blocks <= MAXBLOCKS

Where C<MAXBLOCKS=256> for the fast implementation and C<MAXBLOCKS=65536>
for the slow implementation (the implementation is chosen automatically).

=over 4

=cut

package Algorithm::FEC;

require XSLoader;

no warnings;

$VERSION = '1.1';

XSLoader::load Algorithm::FEC, $VERSION;

=item $fec = new Algorithm::FEC $data_blocks, $encoded_blocks, $blocksize

Creates a new Algorithm::FEC object with the given parameters.

=item $fec->set_encode_blocks ([array_of_blocks])

Sets the data blocks used for the encoding. Each member of the array can either be:

=over 4

=item * a string of size C<blocksize> C<exactly>.

This is useful for small files (encoding entirely in memory).

=item * a filehandle of a file of size C<blocksize> C<exactly>.

This is useful when the amount of data is large and resides in single files.

=item * a reference to an array containing a filehandle and, optionally, an offset into that file.

This is useful if the amount of data is large and resides in a single
file. Needless to say, all parts must not overlap and must fit into the
file.

=back

If your data is not of the required size (i.e. a multiple of C<blocksize>
bytes), then you must pad it (e.g. with zero bytes) on encoding (and you
should truncate it after decoding). Otherwise, this library croaks.

Future versions might instead load the short segment into memory or extend
your scalar (this might enable nice tricks, like C<$fec->copy (..., my
$x)> :). Mail me if you want this to happen.

If called without arguments, the internal storage associated with the
blocks is freed again.

=item $block = $fec->encode ($block_index)

Creates a single encoded block of index C<block_index>, which must be
between C<0> and C<encoded_blocks-1> (inclusive). The blocks from C<0> to
C<data_blocks-1> are simply copies of the original data blocks.

The encoded block is returned as a perl scalar (so the blocks should fit
into memory. If this is a problem for you mail me and I'll make it a file.

=item $fec->set_decode_blocks ([array_of_blocks], [array_of_indices])

Prepares to decode C<data_blocks> of blocks (see C<set_encode_blocks> for
the C<array_of_blocks> parameter).

Since these are not usually the original data blocks, an array of
indices (ranging from C<0> to C<encoded_blocks-1>) must be supplied as
the second arrayref.

Both arrays must have exactly C<data_blocks> entries.

This method also reorders the blocks and index array in place (if
necessary) to reflect the order the blocks will have in the decoded
result.

The index array represents the decoded ordering, in that the n-th entry
in the indices array corresponds to the n-th data block of the decoded
result. The value stored in the n-th place in the array will contain the
index of the encoded data block.

Input blocks with indices less than C<data_blocks> will be moved to their
final position (block k to position k), while the gaps between them will
be filled with check blocks. The decoding process will not modify the
already decoded data blocks, but will modify the check blocks.

That is, if you call this function with C<indices = [4,3,1]>, with
C<data_blocks = 3>, then this array will be returned: C<[0,2,1]>. This
means that input block C<0> corresponds to file block C<0>, input block
C<1> to file block C<2> and input block C<2> to data block C<1>.

You can just iterate over this array and write out the corresponding data
block (although this is inefficient):

   for my $i (0 .. $#idx)
      if ($idx[$i] != $i) # need we move this block?
         copy encoded block $idx[$i] to position $i
      }
   }

The C<copy> method can be helpful here.

This method destroys the block array as set up by C<set_encode_blocks>.

=item $fec->shuffle ([array_of_blocks], [array_of_indices])

The same same as C<set_decode_blocks>, with the exception that the blocks
are not actually set for decoding.

This method is not normally used, but if you want to move blocks
around after reordering and before decoding, then calling C<shuffle>
followed by C<set_decode_blocks> incurs lower overhead than calling
C<set_decode_blocks> twice, as files are not mmapped etc.

=item $fec->decode

Decode the blocks set by a prior call to C<set_decode_blocks>.

This method destroys the block array as set up by C<set_decode_blocks>.

=item $fec->copy ($srcblock, $dstblock)

Utility function that simply copies one block (specified like in
C<set_encode_blocks>) into another. This, btw., destroys the blocks set by
C<set_*_blocks>.

=back

=head1 COMPATIBILITY

The way this module works is compatible with the way freenet
(L<http://freenet.sf.net>) encodes files. Comaptibility to other file
formats or networks is not known, please tell me if you find more examples.

=head1 SEE ALSO

L<Net::FCP>. And the author, who might be happy to receive mail from any
user, just to see that this rather rarely-used module is actually being
used (except for freenet ;)

=head1 BUGS

 * too complicated.
 * largely untested, please change this.
 * file descriptors are not supported, but should be.
 * utility functions for files should be provided.
 * 16 bit version not tested

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de

=cut

1;

