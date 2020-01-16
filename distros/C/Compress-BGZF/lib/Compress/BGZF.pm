package Compress::BGZF 0.006;

use 5.012;
use strict;
use warnings;

1;

__END__

=head1 NAME

Compress::BGZF - Read/write blocked GZIP (BGZF) files

=head1 SYNOPSIS

    use Compress::BGZF::Writer;
    use Compress::BGZF::Reader;

    # create a BGZF file

    my @records = generate_data();
    
    my $fh_out = Compress::BGZF::Writer->new_filehandle( 'somefile.gz' );
    print {$fh_out} $_ for (@records);
    close $fh_out;

    # perform non-sequential reads

    my $fh_in = Compress::BGZF::Reader->new_filehandle( 'somefile.gz' );

    # read 32 bytes from uncompressed file offset 3020 
    seek $fh_in, 3020, 0;
    read $fh_in, my $buffer, 32;
    print "data: $buffer\n";

=head1 DESCRIPTION

C<Compress::BGZF> contains a pair of modules for working with block GZIP (BGZF) files.
BGZF is a specialized GZIP format that is compatible with existing GZIP tools
and libraries, but which allows for fast random access at the cost of a modest
increase in file size. It does this by concatenating together multiple
complete GZIP blocks, each of which has a full header and footer and thus can
be decompressed individually without reading through earlier parts of the
file, and by including an extra field in each header that contains the size of
the block. Upon creation of a Reader object, an index containing the
compressed and uncompressed offsets of the start of each block is either read
from disk or generated from the data itself. C<seek>, C<read>, and C<tell> (or
their object-oriented counterparts) can then be performed on the compressed
file as if it were uncompressed. Seeks are fast, and a worst-case maximum of
64k of preceeding data will be uncompressed in order to reach the data of
interest.

=head2 Selected Implementation Notes

According to the BGZF specification, each GZIP block is limited to 64kb in
size (including an 18 byte header and 8 byte footer). While in theory the
uncompressed size could be larger, limits of the virtual offset calculation
and ease of implementation mean that this size limit is enforced on the
uncompressed data.

Virtual offsets are calculated as follows: for any given position in the
uncompressed file, the virtual offset is calculated from the starting byte
offset A of the block in which it occurs (relative to the compressed file) and
the byte offset B at which it occurs in the uncompressed payload of that
block, such that VO = A << 16 | B. This single value then contains sufficient
information to quickly seek to the given location and begin extracting data.

=head1 METHODS

See individual POD of Reader and Writer modules.

A demonstration is included under bin/ named "bgzip.pl" which is designed to
emulate the functionality of the "bgzip" program that comes with the htslib
distribution.

=head1 AUTHOR

Jeremy Volkening <jdv *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

