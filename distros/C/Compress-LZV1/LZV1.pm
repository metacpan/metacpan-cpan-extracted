=head1 NAME

Compress::LZV1 - extremely leight-weight Lev-Zimpel-Vogt compression

=head1 SYNOPSIS

   use Compress::LZV1;

   $probably_compressed = compress $uncompressed_data;

   $original_data = uncompress $probably_compressed;

=head1 DESCRIPTION

LZV1 is an extremely fast (not that much slower than a pure memcpy)
compression algorithm. It is ideal for applications where you want to save
I<some> space but not at the cost of speed. It is ideal for repetitive
data as well. The module is self-contained and very small (no large
library to be pulled in).

I have no idea wether any patents in any countries apply to this
algorithm, but at the moment it is believed that it is free from any
patents.

=head1 FUNCTIONS

=head2 $compressed = compress $uncompressed

Try to compress the given string as quickly and as much as possible. In
the worst case, the string can enlarge by at most a single byte. Empty
strings yield empty strings. The uncompressed data string must be smaller
than 16MB (1<<24).

The compressed is (currently) in one of two forms:

* a literal 'U', followed by the original, uncompressed data

* a literal 'L', followed by three bytes (big-endian) uncompressed length, followed by the actual LZV1 data

=head2 $decompressed = decompress $compressed

Uncompress the string (compressed by C<compress>) and return the original
data. Decompression errors can result in either broken data (there is no
checksum kept) or a runtime error.

=head1 SEE ALSO

Other Compress::* modules, especially Compress::LZO (for speed) and
Compress::Zlib.

=head1 AUTHOR

This perl extension was written by Marc Lehmann <pcg@goof.com> (See
also http://www.goof.com/pcg/marc/). The original lzv1 code was written
by Hermann Vogt and put under the GPL. (There is also a i386 assembler
version that is not used in this module).

The lzv1 code was accompanied by the following comment:

=over 4

The method presented here is faster and compresses better than lzrw1 and
lzrw1-a. I named it lzv for "Lev-Zimpel-Vogt".  It uses ideas introduced
by Ross Williams in his algorithm lzrw1 [R. N. Williams (1991): "An
Extremly Fast ZIV-Lempel Data Compression Algorithm", Proceedings IEEE
Data Compression Conference, Snowbird, Utah, 362-371] and by Fiala and
Green in their algorithm a1 [E. R. Fiala, D. H. Greene (1989): "Data
Compression with Finite Windows", Communications of the ACM, 4, 490-505].
Because lzv differs strongly from both, I hope there will be no patent
problems. The hashing-method has been stolen from Jean-loup Gailly's
(patent free) gzip.

=back

=head1 BUGS

It seems that the c-code has _big_ alignment problems :(

=cut

package Compress::LZV1;

require Exporter;
require DynaLoader;

$VERSION = 0.04;
@ISA = qw/Exporter DynaLoader/;
@EXPORT = qw(compress decompress);
bootstrap Compress::LZV1 $VERSION;

1;





