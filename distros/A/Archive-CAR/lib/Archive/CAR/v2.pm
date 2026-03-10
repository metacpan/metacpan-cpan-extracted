use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Archive::CAR::v1;
#
class Archive::CAR::v2 v0.0.3 : isa(Archive::CAR::v1) {
    use Archive::CAR::Utils qw[systell];
    #
    field $v2_header : reader;
    field $index     : reader;
    #
    method version ()          {2}
    method to_file ($filename) { Archive::CAR->write( $filename, $self->roots, $self->blocks, 2 ) }

    method read ($fh) {

        # Pragma (11 bytes)
        my $pragma;
        read( $fh, $pragma, 11 );

        # Header (40 bytes)
        my $header_raw;
        read( $fh, $header_raw, 40 );
        my ( $char_raw, $data_offset, $data_size, $index_offset ) = unpack( 'a16 Q< Q< Q<', $header_raw );
        $v2_header = { characteristics => $char_raw, data_offset => $data_offset, data_size => $data_size, index_offset => $index_offset, };

        # Read Index if exists
        if ( $index_offset > 0 ) {
            seek( $fh, $index_offset, 0 );
            $index = '';
            while ( read( $fh, my $buf, 8192 ) ) {
                $index .= $buf;
            }
        }

        # Read CAR v1 data
        seek( $fh, $data_offset, 0 );
        $self->SUPER::read( $fh, $data_size );
        return $self;
    }

    method write ( $fh, $roots, $blocks ) {

        # Pragma
        my $pragma = pack( 'H*', '0aa16776657273696f6e02' );
        print {$fh} $pragma;

        # Header Placeholder (40 bytes)
        my $header_pos = systell($fh);
        print {$fh} pack( 'a40', '' );

        # Write CAR v1 data
        my $data_offset = systell($fh);
        $self->SUPER::write( $fh, $roots, $blocks );
        my $data_size = systell($fh) - $data_offset;

        # Index
        my $index_offset = systell($fh);
        require Archive::CAR::Indexer;
        my $indexer    = Archive::CAR::Indexer->new();
        my $index_data = $indexer->generate_index( $self->blocks );
        print {$fh} $index_data;

        # Backfill Header
        my $current_pos = systell($fh);
        seek( $fh, $header_pos, 0 );

        # characteristics (16 bytes), data_offset (8), data_size (8), index_offset (8)
        my $header_raw = pack( 'a16 Q< Q< Q<', "\0" x 16, $data_offset, $data_size, $index_offset );
        print {$fh} $header_raw;
        seek( $fh, $current_pos, 0 );
    }

    # Override header to include v2 fields and v1 roots as expected in some outputs
    method header () {
        my $v1_header = $self->SUPER::header;
        return { %$v2_header, roots => $v1_header->{roots}, version => 2, };
    }
};
#
1;
