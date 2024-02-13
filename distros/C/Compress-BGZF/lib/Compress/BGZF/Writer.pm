package Compress::BGZF::Writer;

use strict;
use warnings;

use Carp;
use Compress::Zlib;
use IO::Compress::RawDeflate qw/rawdeflate $RawDeflateError/;

use constant HEAD_BYTES  => 18;
use constant FOOT_BYTES  => 8;
use constant FLUSH_SIZE  => 2**16 - HEAD_BYTES - FOOT_BYTES - 1;
use constant BGZF_HEADER => pack "H*", '1f8b08040000000000ff060042430200';
use constant BGZF_EOF    => pack "H*",
    '1f8b08040000000000ff0600424302001b0003000000000000000000';

## no critic
# allow for filehandle tie'ing
sub TIEHANDLE { Compress::BGZF::Writer::new(@_) }
sub PRINT     { Compress::BGZF::Writer::_queue(@_) }
sub CLOSE     { Compress::BGZF::Writer::finalize(@_) }
## use critic

sub new_filehandle {

    #-------------------------------------------------------------------------
    # ARG 0 : (optional) output filename
    #-------------------------------------------------------------------------
    # RET 0 : filehandle GLOB
    #-------------------------------------------------------------------------

    my ($class, $fn_out) = @_;

    open my $fh, '<', undef;
    tie *$fh, $class, $fn_out or croak "failed to tie filehandle";
    return $fh;

}

sub new {

    #-------------------------------------------------------------------------
    # ARG 0 : (optional) output filename
    #-------------------------------------------------------------------------
    # RET 0 : Compress::BGZF::Writer object
    #-------------------------------------------------------------------------

    my ($class, $fn_out) = @_;
    my $self = bless {}, $class;

    # initialize
    if (defined $fn_out) {
        open $self->{fh}, '>', $fn_out
            or croak "Error opening file for writing";
    }
    else {
        $self->{fh} = \*STDOUT;
    }
    binmode $self->{fh};

    $self->{c_level} = Z_DEFAULT_COMPRESSION;
    $self->{buffer}  = ''; # contents waiting to be compressed/written

    # these variables are tracked to allow for virtual offset calculation
    $self->{block_offset}  = 0;  # offset of current block in compressed data
    $self->{buffer_offset} = 0;  # offset of current pos in uncompressed block

    # these variables are tracked to allow for index creation
    $self->{u_offset} = 0; #uncompressed file offset
    $self->{idx} = [];
    $self->{write_eof} = 0;

    return $self;

}

sub set_level {

    #-------------------------------------------------------------------------
    # ARG 0 : compression level desired
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self, $level) = @_;

    croak "Invalid compression level (allowed 0-9)"
        if ($level !~ /^\d$/);
    $self->{c_level} = $level;

    return;

}

sub set_write_eof {

    # Sets whether to include htslib-style EOF empty block at end of file

    #-------------------------------------------------------------------------
    # ARG 0 : (optional) boolean
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self, $bool) = @_;

    $bool //= 1;
    $self->{write_eof} = $bool ? 1 : 0;

    return;

}

sub add_data {

    # a wrapper around the queue() function that returns the virtual offset
    # of the chunk added

    #-------------------------------------------------------------------------
    # ARG 0 : data chunk to queue for compression
    #-------------------------------------------------------------------------
    # RET 1 : virtual offset of data written
    #-------------------------------------------------------------------------

    my ($self, $content) = @_;

    my $vo =  ($self->{block_offset} << 16) | $self->{buffer_offset};
    $self->_queue( $content );

    return $vo;

}

sub _queue {

    #-------------------------------------------------------------------------
    # ARG 0 : data chunk to queue for compression
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self, $content) = @_;

    $self->{buffer} .= $content;

    # compress/write in 64k chunks
    while (length($self->{buffer}) >= FLUSH_SIZE) {

        my $chunk = substr $self->{buffer}, 0, FLUSH_SIZE, '';
        my $unwritten = $self->_write_block($chunk);
        $self->{buffer} = $unwritten . $self->{buffer}
            if ( length($unwritten) );

    }
    $self->{buffer_offset} = length $self->{buffer};

    return;
    
}

sub _write_block {

    #-------------------------------------------------------------------------
    # ARG 0 : independent data block to compress
    #-------------------------------------------------------------------------
    # RET 0 : remaining data that wasn't written
    #-------------------------------------------------------------------------

    my ($self, $chunk) = @_;

    my $chunk_len = length($chunk);

    # payload is compressed with DEFLATE
    rawdeflate(\$chunk, \my $payload, -Level => $self->{c_level})
        or croak "deflate failed: $RawDeflateError\n";

    # very rarely, a DEFLATEd string may be larger than input. This can result
    # in a block size > 2**16, which violates the BGZF specification and
    # causes corruption of the BC field. Fix those edge cases here (somewhat
    # slow but shouldn't happen often) and send the rest back to the buffer
    my $trimmed = '';
    while (length($payload) > FLUSH_SIZE) {
        my $trim_len = int( $chunk_len * 0.05 );
        $trimmed = substr($chunk, -$trim_len, $trim_len, '') . $trimmed;
        rawdeflate(\$chunk, \$payload, -Level => $self->{c_level})
            or croak "deflate failed: $RawDeflateError\n";
        $chunk_len = length($chunk);
    }

    my $block_size = length($payload) + HEAD_BYTES + FOOT_BYTES;

    croak "Internal error: block size > 65536" if ($block_size > 2**16);

    # payload is wrapped with appropriate headers and footers
    print { $self->{fh} } pack(
        "a*va*VV",
        BGZF_HEADER,
        $block_size - 1,
        $payload,
        crc32($chunk),
        $chunk_len,
    ) or croak "Error writing compressed block";

    # increment the current offsets
    $self->{block_offset} += $block_size;
    $self->{u_offset}     += $chunk_len;
    push @{ $self->{idx} }, [$self->{block_offset}, $self->{u_offset}];

    return $trimmed;

}

sub finalize {

    #-------------------------------------------------------------------------
    # no arguments
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self) = @_;

    while (length($self->{buffer}) > 0) {

        croak "file closed but buffer not empty"
            if ( ! defined fileno($self->{fh}) );

        my $chunk = substr $self->{buffer}, 0, FLUSH_SIZE, '';
        my $unwritten = $self->_write_block($chunk);
        $self->{buffer} = $unwritten . $self->{buffer}
            if ( length($unwritten) );

    }
    # write EOF block if requested (only first time finalize() is run)
    if ($self->{write_eof} && defined fileno($self->{fh})) {
        print { $self->{fh} } BGZF_EOF;
    }
    if (defined fileno($self->{fh}) ) {
        close $self->{fh}
            or croak "Error closing compressed file";
    }

    return;

}

sub write_index {

    #-------------------------------------------------------------------------
    # ARG 0 : index output filename
    #-------------------------------------------------------------------------
    # No returns
    #-------------------------------------------------------------------------

    my ($self, $fn_out) = @_;

    $self->finalize(); # always clear remaining buffer to fully populate index
    croak "missing index output filename" if (! defined $fn_out);
    open my $fh_out, '>:raw', $fn_out
        or croak "Error opening index file for writing";

    my @offsets = @{ $self->{idx} };
    pop @offsets; # last offset is EOF
    print {$fh_out} pack('Q<', scalar(@offsets))
        or croak "Error printing to index file";
    for (@offsets) {
        print {$fh_out} pack('Q<Q<', @{$_})
            or croak "Error printing offset to index file";
    }

    close $fh_out
        or croak "Error closing index file after writing";
    return;

}

sub DESTROY {

    my ($self) = @_;

    # make sure we call finalize in case the caller forgot
    $self->finalize();

    return;

}

1;


__END__

=head1 NAME

Compress::BGZF::Writer - Performs blocked GZIP (BGZF) compression

=head1 SYNOPSIS

    use Compress::BGZF::Writer;

    # Use as filehandle
    my $fh_bgz = Compress::BGZF::Writer->new_filehandle( $bgz_filename );
    print ref($writer), "\n"; # prints 'GLOB'
    while ( my $chunk = generate_data() ) {
        print {$fh_bgz} $chunk;
    }
    close $fh_bgz;

    # Use as object
    my $writer = Compress::BGZF::Writer->new( $bgz_filename );
    print ref($writer), "\n"; # prints 'Compress::BGZF::Writer'
    while ( my ($id,$content) = generate_record() ) {
        my $virt_offset = $writer->add_data( $content );
        my $content_len = length $content;
        print {$idx_file} "$id\t$virt_offset\t$content_len\n";
    }
    $writer->finalize(); # flush remaining buffer;

=head1 DESCRIPTION

C<Compress::BGZF::Writer> is a module for writing blocked GZIP (BGZF) files from
any input. There are two main modes of construction - as an object (using
C<new()>) and as a filehandle glob (using C<new_filehandle>). The filehandle
mode is straightforward for general use. The object mode is useful for
tracking the virtual offsets of data chunks as they are added (for instance,
for generation of a custom index).

=head1 METHODS

=head2 Filehandle Functions

=over 4

=item B<new_filehandle>

    my $fh_out = Compress::BGZF::Writer->new_filehandle();
    my $fh_out = Compress::BGZF::Writer->new_filehandle( $output_fn );

Create a new C<Compress::BGZF::Writer> engine and tie it to a IO::File handle,
which is returned. Takes an optional single argument
for the filename to be written to (defaults to STDOUT).

=item B<print>

=item B<close>

    print {$fh_out} $some_data;
    close $fh_out;

These functions emulate the standard perl functions of the same name.

=back

=head2 0bject-oriented Methods

=over 4

=item B<new>

    my $writer = Compress::BGZF::Writer->new();
    my $writer = Compress::BGZF::Writer->new( $output_fn );

Create a new C<Compress::BGZF::Writer> engine. Takes an optional single argument
for the filename to be written to (defaults to STDOUT).

=item B<set_level>

    $writer->set_level( $compression_level );

Set the DEFLATE compression level to use (0-9). Available constants include
Z_NO_COMPRESSION, Z_BEST_SPEED, Z_DEFAULT_COMPRESSION, Z_BEST_COMPRESSION
(defaults to Z_DEFAULT_COMPRESSION). The author's observations suggest that
the default is reasonable unless speed is of the essence, in which case
setting a level of 1-2 can sometimes halve the compression time.

=item B<set_write_eof>

    $writer->set_write_eof;    # turn on
    $writer->set_write_eof(1); # turn on
    $writer->set_write_eof(0); # turn off

The L<htslib|https://github.com/samtools/htslib> C<bgzf.c> library, which
might be considered the reference BGZF implementation, uses a special empty
block to indicate EOF as an extra check of file integrity. This class method
turns on or off a flag telling the C<Compress::BGZF::Writer> object whether to
append this special block to the output file for the sake of compatability.
Default: off.

=item B<add_data>

    $writer->add_data( $content );

Adds a block of conent to the write buffer. Actual compression/writes take place as
the buffer reaches the target size (64k minus header/footer space). Returns
the virtual offset to the start of the data added.

=item B<finalize>

    $writer->finalize();

Write any remaining buffer contents. While this method should be automatically
called during cleanup of the Compress::BGZF::Writer object, it is
probably safer to call it explicitly to avoid unexpected behavior. Keep in
mind that if both you and the object destruction process fail to call this,
you will almost certainly generate an incomplete file (and probably won't
notice since it will still be valid BGZF).

=item B<write_index>

    $writer->write_index( $index_fn );

Write offset index to the specified file.  Index format (as defined by htslib)
consists of little-endian int64-coded values. The first value is the number of
offsets in the index. The rest of the values consist of pairs of block offsets
relative to the compressed and uncompressed data. The first offset (always
0,0) is not included.

Note that calling C<write_index()> will also call C<finalize()> and so should
always be called after all data has been queued for write (it is hard to
imagine a case where this would not be the desirable behavior).

For small(er) files (up to a few hundred MB) on-the-fly index generation with
Compress::BGZF::Reader is relatively fast and an on-disk index is probably not
necessary. For larger files, storing a paired index file can signficantly
decrease initialization times for Compress::BGZF::Reader objects.

These index files should be fully compatible with the htslib bgzip tool.

=back

=head1 CAVEATS AND BUGS

This is code is in alpha testing stage. The filehandle behavior should not
change in the future, but the object-oriented API is not guaranteed to be
stable.

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jeremy *at* base2bio.com>

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

