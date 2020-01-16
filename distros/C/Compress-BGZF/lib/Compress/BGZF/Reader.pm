package Compress::BGZF::Reader;

use strict;
use warnings;

use Carp;
use Compress::Zlib;
use List::Util qw/sum/;
use FileHandle;

use constant BGZF_MAGIC => pack "H*", '1f8b0804';
use constant HEAD_BYTES => 12; # not including extra fields
use constant FOOT_BYTES => 8;

## no critic
# allow for filehandle tie'ing
sub TIEHANDLE { Compress::BGZF::Reader::new(@_) }
sub READ      { Compress::BGZF::Reader::_read(@_) }
sub READLINE  { Compress::BGZF::Reader::getline(@_) }
sub SEEK      { Compress::BGZF::Reader::_seek(@_) }
sub CLOSE     { close  $_[0]->{fh} }
sub TELL      { return $_[0]->{u_offset} }
sub EOF       { return $_[0]->{buffer_len} == -1 }
sub FILENO    { return fileno $_[0]->{fh} }

# accessors
sub usize { return $_[0]->{u_file_size} };

## use critic

sub new_filehandle {

    #-------------------------------------------------------------------------
    # ARG 0 : BGZF input filename
    #-------------------------------------------------------------------------
    # RET 0 : Filehandle GLOB (internally an IO::File object tied to
    #         Compress::BGZF::Reader)
    #-------------------------------------------------------------------------

    my ($class, $fn_in) = @_;
    croak "input filename required" if (! defined $fn_in);
    my $fh = FileHandle->new;
    tie *$fh, $class, $fn_in or croak "failed to tie filehandle";
    #tie *FH, $class, $fn_in or croak "failed to tie filehandle";

    return $fh;
    #return \*FH;

}

sub new {

    #-------------------------------------------------------------------------
    # ARG 0 : BGZF input filename
    #-------------------------------------------------------------------------
    # RET 0 : Compress::BGZF::Reader object
    #-------------------------------------------------------------------------
    
    my ($class, $fn_in) = @_;
    my $self = bless {}, $class;

    # initialize
    $self->{fn_in} = $fn_in
        or croak "Input name required";

    # open compressed file in binary mode
    open my $fh, '<:raw', $fn_in or croak "Failed to open input file"; ## no critic
    $self->{fh} = $fh;

    # these member variables allow for data extraction
    $self->{buffer}        = ''; # contents of currently uncompressed block
    $self->{buffer_len}    = 0;  # save time on frequent length() calls
    $self->{block_offset}  = 0;  # offset of current block in compressed data
    $self->{buffer_offset} = 0;  # offset of current pos in uncompressed block
    $self->{block_size}    = 0;  # compressed size of current block
    $self->{file_size}     = -s $fn_in; # size of compressed file

    # these variables are tracked to allow for full seek implementation
    $self->{u_offset}      = 0;  # calculated current uncompressed offset 
    $self->{u_file_size}   = 0;  # size of uncompressed file (filled during
                                 #  indexing

    # load offset index
    if (-e "$fn_in.gzi") {
        $self->_load_index( "$fn_in.gzi" ); # from disk
    }
    else {
        $self->_generate_index(); # on-the-fly
    }

    # load initial block
    $self->_load_block();

    return $self;

}

sub _load_block {
    
    #-------------------------------------------------------------------------
    # ARG 0 : offset of block start in compressed file
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self, $block_offset) = @_;

    # loading a block should always reset buffer offset
    $self->{buffer_offset} = 0;

    # avoid reload of current block
    return if (defined $block_offset
        && $block_offset == $self->{block_offset});

    # if no offset given (e.g. sequential reads), move to next block
    if (! defined $block_offset) {
        $block_offset = $self->{block_offset} + $self->{block_size};
    }

    $self->{block_offset} = $block_offset;
    # deal with EOF
    croak "Read past file end (perhaps corrupted/truncated input?)"
        if ($self->{block_offset} > $self->{file_size});
    if ($self->{block_offset} == $self->{file_size}) {
        $self->{buffer} = '';
        $self->{buffer_len} = -1;
        return;
    }

    # never assume we're already there
    sysseek $self->{fh}, $self->{block_offset}, 0;

    # parse block according to GZIP spec, including content inflation
    my ($block_size, $uncompressed_size, $content)
        = $self->_unpack_block(1);
    $self->{block_size} = $block_size;
    $self->{buffer_len} = $uncompressed_size;
    $self->{buffer}     = $content;

    return;

}

sub _unpack_block {

    #-------------------------------------------------------------------------
    # ARG 0 : bool indicating whether to inflate (and return) actual payload
    #-------------------------------------------------------------------------
    # RET 0 : compressed block size
    # RET 1 : uncompressed content size
    # RET 2 : content (if ARG 0)
    #-------------------------------------------------------------------------

    my ($self, $do_unpack) = @_;

    my @return_values;


    my ($magic, $mod, $flags, $os, $len_extra) = unpack 'A4A4CCv',
        _safe_sysread($self->{fh}, HEAD_BYTES);
    my $t = sysseek $self->{fh}, 0, 1;
    croak "invalid header at $t (corrupt file or not BGZF?)"
        if ($magic ne BGZF_MAGIC);

    # extract stated block size according to BGZF spec
    my $block_size;
    my $l = 0;
    while ($l < $len_extra) {
        my ($field_id, $field_len) = unpack 'A2v',
            _safe_sysread($self->{fh}, 4);
        if ($field_id eq 'BC') {
            croak "invalid BC length" if ($field_len != 2);
            croak "multiple BC fields" if (defined $block_size);
            $block_size = unpack 'v',
                _safe_sysread($self->{fh} => $field_len);
            $block_size += 1; # convert to 1-based
        }
        $l += 4 + $field_len;
    }
    croak "invalid extra field length" if ($l != $len_extra);
    croak "failed to read block size" if (! defined $block_size);

    push @return_values, $block_size;
    my $payload_len = $block_size - HEAD_BYTES - FOOT_BYTES - $len_extra;
    my $content;
    if ($do_unpack) {
        
        # decode actual content
        my $payload = _safe_sysread($self->{fh}, $payload_len);
        my ($i,$status) = inflateInit(-WindowBits => -&MAX_WBITS());
        croak "Error during inflate init\n" if ($status != Z_OK);
        ($content,$status) = $i->inflate($payload);
        croak "Error during inflate run\n" if ($status != Z_STREAM_END);
        #rawinflate( \$payload => \$content )
            #or croak "Error inflating: $RawInflateError\n";
        my $crc_given = unpack 'V', _safe_sysread($self->{fh} => 4);
        croak "content CRC32 mismatch" if ( $crc_given != crc32($content) );

    }
    else { sysseek $self->{fh}, $payload_len + 4, 1; }

    # unpack and possibly check uncompressed payload size
    my $size_given = unpack 'V', _safe_sysread($self->{fh} => 4);
    croak "content length mismatch"
        if ( defined $content && $size_given != length($content) );
    push @return_values, $size_given;
    push @return_values, $content if (defined $content);

    return @return_values;

}

sub read_data {

    # More OO-ish wrapper around _read(), avoids conflicts with system read()

    #-------------------------------------------------------------------------
    # ARG 0 : number of bytes to read
    #-------------------------------------------------------------------------
    # RET 0 : data read
    #-------------------------------------------------------------------------

    my ($self, $bytes) = @_;

    my $r = $self->_read( my $buffer, $bytes );
    carp "received fewer bytes than requested"
        if ($r < $bytes && $self->{buffer_len} > -1);
   
    $buffer = undef if ( $r < 1 );
    return $buffer;
   
}

sub _read {

    #-------------------------------------------------------------------------
    # ARG 0 : buffer to write to
    # ARG 1 : bytes to attempt to read
    # ARG 3 : (optional) offset in buffer to start write (default: 0)
    #-------------------------------------------------------------------------
    # RET 0 : bytes read (0 at EOF, undef on error)
    #-------------------------------------------------------------------------

    # we try to emulate the built-in 'read' call, so we will
    # overwrite $_[1] and return the number of bytes read. To facilitate this,
    # make $buf a reference to the buffer passed
    my $self   = shift;
    my $buf    = \shift; # must be a reference !!
    my $bytes  = shift;
    my $offset = shift;

    # handle cases when $offset is passed in
    my $prefix = '';
    if (defined $offset && $offset != 0) {
        $prefix = substr $$buf, 0, $offset;
        $prefix .= "\0" x ( $offset - length($$buf) )
            if ( $offset > length($$buf) );
    }

    $$buf = ''; # reset (only AFTER grabbing any prefix above)

    ITER:
    while (length($$buf) < $bytes) {

        my $l = length($$buf);
        my $remaining = $bytes - $l;

        # if read is within current block
        if ($self->{buffer_offset} + $remaining <= $self->{buffer_len}) {
            $$buf .= substr $self->{buffer}, $self->{buffer_offset}, $remaining;
            $self->{buffer_offset} += $remaining;
            $self->_load_block()
                if ($self->{buffer_offset} == $self->{buffer_len});
        }
        else {
            last ITER if ($self->{buffer_len} < 0); #EOF
            $$buf .= substr $self->{buffer}, $self->{buffer_offset};
            $self->_load_block();
        }

    }

    my $l = length($$buf);
    $self->{u_offset} += $l;
    $$buf = $prefix . $$buf;

    return $l;

}


sub getline {

    #-------------------------------------------------------------------------
    # No arguments
    #-------------------------------------------------------------------------
    # RET 0 : string read (undef at EOF)
    #-------------------------------------------------------------------------

    my ($self) = @_;

    my $data = '';

    while (1) {

        # return immediately if EOF
        last if ($self->{buffer_len} < 0);

        # search current block for record separator
        # start searching from the current buffer offset
        pos($self->{buffer}) = $self->{buffer_offset};

        if ($self->{buffer} =~ m|$/|g) {
            my $pos = pos $self->{buffer};
            $data .= substr $self->{buffer}, $self->{buffer_offset},
                $pos - $self->{buffer_offset};

            $self->{buffer_offset} = $pos;

            # if we're at the end of the block, load next
            $self->_load_block if ($pos == $self->{buffer_len});

            $self->{u_offset} += length($data);

            last;

        }

        # otherwise, add rest of block to data and load next block
        $data .= substr $self->{buffer}, $self->{buffer_offset};
        $self->_load_block;

    }

    return length($data) > 0 ? $data : undef;

}

sub write_index {

    # index format (as defined by htslib) consists of little-endian
    # int64-coded values. The first value is the number of offsets in the
    # index. The rest of the values consist of pairs of block offsets relative
    # to the compressed and uncompressed data. The first offset (always 0,0)
    # is not included.

    #-------------------------------------------------------------------------
    # ARG 0 : index output filename
    #-------------------------------------------------------------------------
    # No returns
    #-------------------------------------------------------------------------

    my ($self, $fn_out) = @_;

    croak "missing index output filename" if (! defined $fn_out);


    $self->_generate_index() if (! defined $self->{idx});
    my @offsets = @{ $self->{idx} };
    shift @offsets; # don't write first

    open my $fh_out, '>:raw', $fn_out;

    print {$fh_out} pack('Q<', scalar(@offsets));
    for (@offsets) {
        print {$fh_out} pack('Q<', $_->[0]);
        print {$fh_out} pack('Q<', $_->[1]);
    }

    close $fh_out;

    return;

}

sub _load_index {

    #-------------------------------------------------------------------------
    # ARG 0 : index input filename
    #-------------------------------------------------------------------------
    # No returns
    #-------------------------------------------------------------------------

    my ($self, $fn_in) = @_;
    croak "missing index input filename" if (! defined $fn_in);

    #TODO: speed up index parsing

    open my $fh_in, '<:raw', $fn_in or croak "error opening index";
    read( $fh_in, my $n_offsets, 8)
        or croak "failed to read first quad";
    $n_offsets = unpack 'Q<', $n_offsets;
    my @idx;
    for (0..$n_offsets-1) {
        read( $fh_in, my $buff, 16) or croak "error reading index";
        $idx[$_] = [ unpack 'Q<Q<', $buff ];
    }
    close $fh_in;
    unshift @idx, [0,0]; # add initial offsets

    $self->{u_file_size} = $idx[-1]->[1];

    # some indices created by htslib bgzip are missing last offset pair
    # check for that here by loading last block in index and proceeding from
    # there. Also calculate uncompressed file size at the same time.
    my $c_size = $idx[-1]->[0];
    sysseek $self->{fh}, $idx[-1]->[0], 0;
    my ($c, $u) = $self->_unpack_block(0);
    $self->{u_file_size} += $u;
    $c_size += $c;
    while ($c_size < $self->{file_size}) {
        push @idx, [$idx[-1]->[0]+$c, $idx[-1]->[1]+$u];
        sysseek $self->{fh}, $idx[-1]->[0], 0;
        ($c, $u) = $self->_unpack_block(0);
        $self->{u_file_size} += $u;
        $c_size += $c;
    }
    croak "Unexpected file size/last index mismatch ($c_size v $self->{file_size})"
        if ($c_size != $self->{file_size});

    $self->{idx} = [@idx];
    $self->{ridx}->{$_->[0]} = $_->[1] for (@idx);

    sysseek $self->{fh}, $self->{block_offset}, 0;

    return;

}

sub _generate_index {

    #-------------------------------------------------------------------------
    # No arguments
    #-------------------------------------------------------------------------
    # No returns
    #-------------------------------------------------------------------------

    my ($self) = @_;

    my $uncmp_offset     = 0;
    my $cmp_offset       = 0;
    my $i                = 0;
    $self->{u_file_size} = 0;
    $self->{idx}         = [];
    $self->{ridx}        = {};

    sysseek $self->{fh}, 0, 0;

    while ($cmp_offset < $self->{file_size}) {

        push @{$self->{idx}}, [$cmp_offset, $uncmp_offset];
        $self->{ridx}->{$cmp_offset} = $uncmp_offset;

        my ($block_size, $uncompressed_size) = $self->_unpack_block(0);

        $cmp_offset += $block_size;
        $uncmp_offset += $uncompressed_size;
        $self->{u_file_size} += $uncompressed_size;

    }

    sysseek $self->{fh}, $self->{block_offset}, 0;

    return;

}


sub move_to {

    # Wrapper around _seek(), avoids conflicts with system seek()

    #-------------------------------------------------------------------------
    # ARG 0 : byte offset to which to seek
    # ARG 1 : relativity of offset (0: file start, 1: current, 2: file end)
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    
    my ($self, @args) = @_;
    $self->_seek( @args );

    return;

}


sub _seek {

    #-------------------------------------------------------------------------
    # ARG 0 : byte offset to which to seek
    # ARG 1 : relativity of offset (0: file start, 1: current, 2: file end)
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self, $pos, $whence) = @_;

    $pos += $self->{u_offset} if ($whence == 1);
    $pos  = $self->{u_file_size} + $pos if ($whence == 2);

    return if ($pos < 0);
    if ($pos >= $self->{u_file_size}) {
        $self->{buffer_len} = -1;
        $self->{u_offset} = $pos;
        $self->{block_offset} = $pos;
        return 1;
    }

    # Do seeded search for nearest block start <= $pos
    # (although we don't know the size of each block, we can determine the
    # mean length and usually choose a starting value close to the actual -
    # benchmarks much faster than binary search)
    # TODO: benchmark whether breaking this out and Memoizing speeds things up

    my $s = scalar @{$self->{idx}};
    my $idx = int($pos/($self->{u_file_size}) * $s);
    while (1) {
        if ($pos < $self->{idx}->[$idx]->[1]) {
            --$idx;
            next;
        }
        if ($idx+1 < $s && $pos >= $self->{idx}->[$idx+1]->[1]) {
            ++$idx;
            next;
        }
        last;
    }

    my $block_o   = $self->{idx}->[$idx]->[0];
    my $block_o_u = $self->{idx}->[$idx]->[1];
    my $buff_o    = $pos - $block_o_u;

    $self->_load_block( $block_o );
    $self->{buffer_offset} = $buff_o;
    $self->{u_offset} = $block_o_u + $buff_o;

    return 1;

}

sub get_vo {

    #-------------------------------------------------------------------------
    # no arguments
    #-------------------------------------------------------------------------
    # RET 0 : virtual offset of current position
    #-------------------------------------------------------------------------

    my ($self) = @_;
    return  ($self->{block_offset} << 16) | $self->{buffer_offset};

}

sub move_to_vo {

    #-------------------------------------------------------------------------
    # ARG 0 : virtual offset (see POD for definition)
    #-------------------------------------------------------------------------
    # no returns
    #-------------------------------------------------------------------------

    my ($self, $vo) = @_;
    my $block_o = $vo >> 16;
    my $buff_o  = $vo ^ ($block_o << 16);
    $self->_load_block( $block_o );
    $self->{buffer_offset} = $buff_o;
    croak "invalid block offset" if (! defined $self->{ridx}->{$block_o});
    $self->{u_offset} = $self->{ridx}->{$block_o} + $buff_o;

    return;

}

sub _safe_sysread {

    # sysread wrapper that checks return count and returns read
    # (internally we should never read off end of file - doing so indicates
    # either a software bug or a corrupt input file so we croak)

    #-------------------------------------------------------------------------
    # ARG 0 : bytes to read
    #-------------------------------------------------------------------------
    # RET 0 : string read
    #-------------------------------------------------------------------------

    my ($fh, $len) = @_;
    my $buf = '';
    my $r = sysread $fh, $buf, $len;
    croak "returned unexpected byte count" if ($r != $len);

    return $buf;

}

1;


__END__

=head1 NAME

Compress::BGZF::Reader - Performs blocked GZIP (BGZF) decompression

=head1 SYNOPSIS

    use Compress::BGZF::Reader;

    # Use as filehandle
    my $fh_bgz = Compress::BGZF::Reader->new_filehandle( $bgz_filename );

    # you can do this, but it's probably faster just to pipe gunzip
    while (my $line = <$fh_bgz>) {
        print $line;
    }

    # here's the random-access goodness
    # fetch 32 bytes from uncompressed offset 1001
    seek $fh_bgz, 1001, 0;
    read $fh_bgz, my $data, 32;
    print $data;

    # Use as object
    my $reader = Compress::BGZF::Reader->new( $bgz_filename );

    # Move to a virtual offset (somehow pre-calculated) and read 32 bytes
    $reader->move_to_vo( $virt_offset );
    my $data = $reader->read_data(32);
    print $data;

    $reader->write_index( $fn_idx );

=head1 DESCRIPTION

C<Compress::BGZF::Reader> is a module implementing random access to the BGZIP file
format. While it can do sequential/streaming reads, there is really no point
in using it for this purpose over standard GZIP tools/libraries, since BGZIP
is GZIP-compatible.

There are two main modes of construction - as an object (using C<new()>) and
as a filehandle glob (using C<new_filehandle>). The filehandle mode is
straightforward for general use (emulating seek/read/tell functionality and
passing to other classes/methods that expect a filehandle).  The object mode
has additional features such as seeking to virtual offsets and dumping the
offset index to file.

=head1 METHODS

=head2 Filehandle Functions

=over 4

=item B<new_filehandle>

    my $fh_bgzf = Compress::BGZF::Writer->new_filehandle( $input_fn );

Create a new C<Compress::BGZF::Reader> engine and tie it to a IO::File handle,
which is returned. Takes a mandatory single argument for the filename to be
read from.

=item B<< <> >>

=item B<readline>

=item B<seek>

=item B<read>

=item B<tell>

=item B<eof>

    my $line = <$fh_bgzf>;
    my $line = readline $fh_bgzf;
    seek $fh_bgzf, 256, 0;
    read $fh_bgzf, my $buffer, 32;
    my $loc = tell $fh_bgzf;
    print "End of file\n" if eof($fh_bgzf);

These functions emulate the standard perl functions of the same name.

=back

=head2 Object-oriented Methods

=over 4

=item B<new>

    my $reader = Compress::BGZF::Reader->new( $fn_in );

Create a new C<Compress::BGZF::Reader> engine. Requires a single argument - the
name of the BGZIP file to be read from.

=item B<move_to>

    $reader->move_to( 493, 0 );

Seeks to the given uncompressed offset. Takes two arguments - the requested
offset and the relativity of the offset (0: file start, 1: current, 2: file end)

=item B<move_to_vo>

    $reader->move_to_vo( $virt_offset );

Like C<move_to>, but takes as a single argument a virtual offset. Virtual
offsets are described more in the top-level documentation for C<Compress::BGZF>.

=item B<get_vo>

    $reader->get_vo();

Returns the virtual offset of the current read position

=item B<read_data>

    my $data = $reader->read_data( 32 );

Read uncompressed data from the current location. Takes a single argument -
the number of bytes to be read - and returns the data read or C<undef> if at
C<EOF>.

=item B<getline>

    my $line = $reader->getline();

Reads one line of uncompressed data from the current location, shifting the
current file offset accordingly. Returns the line read or C<undef> if
currently at C<EOF>.

=item B<usize>

    my $size = $reader->usize();

Returns the uncompressed size of the file, as calculated during indexing.

=item B<write_index>

    $reader->write_index( $fn_index );

Writes the compressed index to file. The index format (as defined by htslib)
consists of little-endian int64-coded values. The first value is the number of
offsets in the index. The rest of the values consist of pairs of block offsets
relative to the compressed and uncompressed data. The first offset (always
0,0) is not included. The index files written by Compress::BGZF should be
compatible with those of the htslib C<bgzip> software, and vice versa.

=back

=head1 NEWLINES

Note that when using the tied filehandle interface, the behavior of the module
will replicate that of a file opened in raw mode. That is, none of the Perl
magic concerning platform-specific newline conversions will be performed. It's
expected that users of this module will generally be seeking to predetermined
byte offsets in a file (such as read from an index), and operations such as
C<seek>, C<read>, and C<< <> >> are not reliable in a cross-platform way on
files opened in 'text' mode. In other words, seeking to and reading from a
specific offset in 'text' mode may return different results depending on the
platform Perl is running on. This isn't an issue specific to this module but
to Perl in general. Users should simply be aware that any data read using this
module will retain its original line endings, which may not be the same as
those of the current platform.

For a further discussion, see
L<http://perldoc.perl.org/perlport.html#Newlines>.

=head1 CAVEATS AND BUGS

This is code is in alpha testing stage and the API is not guaranteed to be
stable.

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

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

