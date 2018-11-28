package Data::RecordStore::Converter;

use strict;
use warnings;

use Data::RecordStore;

package Data::RecordStore::Converter::OldSilo;

use strict;
use warnings;
no warnings 'uninitialized';

use Fcntl qw( SEEK_SET LOCK_EX LOCK_UN );
use File::Copy;

=head2 open( template, filename, size )

Opens or creates the file given as a fixed record 
length data store. If a size is not given,
it calculates the size from the template, if it can.
This will die if a zero byte record size is determined.

=cut
sub _open {
    my( $class, $template, $filename, $size ) = @_;
    my $FH;
    my $useSize = $size;
    if( ! $useSize ) {
      $useSize = do { use bytes; length( pack( $template ) ) };
    }

    CORE::open $FH, "<", $filename;
    bless { TMPL        => $template, 
            RECORD_SIZE => $useSize,
            FILENAME    => $filename,
    }, $class;
} #open


=head2

Returns the number of entries in this store.
This is the same as the size of the file divided
by the record size.

=cut
sub entry_count {
    # return how many entries this index has
    my $self = shift;
    my $fh = $self->_filehandle;
    my $filesize = -s $self->{FILENAME};
    int( $filesize / $self->{RECORD_SIZE} );
}

sub get_record {
    my( $self, $idx ) = @_;

    my $fh = $self->_filehandle;
    sysseek $fh, $self->{RECORD_SIZE} * ($idx-1), SEEK_SET;
    sysread $fh, my $data, $self->{RECORD_SIZE};
    [unpack( $self->{TMPL}, $data )];
} #get_record

sub _filehandle {
    my $self = shift;
    CORE::open( my $fh, "<", $self->{FILENAME} );
    $fh;
}

package Data::RecordStore::Converter;

=head2 convert( $source_dir, $dest_dir )

Analyzes the source directory to find version
then creates a new version of the store in the
destination directory.

=cut
sub convert {
    my( $source_dir, $dest_dir ) = @_;

    die "Data::RecordStore::Converter::convert must be given a destination directory" unless $dest_dir;

    die "Data::RecordStore::Converter::convert cannot find source directory '$source_dir'" unless -d $source_dir;

    my $ver_file = "$source_dir/VERSION";
    my $source_version = 0;
    if ( -e $ver_file ) {
        CORE::open( my $FH, "<", $ver_file );
        $source_version = <$FH>;
        chomp $source_version;
        close $FH;
    }

    if( $source_version >= 4 ) {
        warn "Database at '$source_dir' already at version $source_version. Doing nothing\n";
        return;
    }

    my $converter = bless {
      source_dir => $source_dir,
      dest_dir   => $dest_dir,
      to_silos   => [],
      to_index   => Data::RecordStore::Silo->open_silo( "IL", "$dest_dir/RECORD_INDEX_SILO" ),
    }, 'Data::RecordStore::Converter';
    if ( $source_version < 2 ) {
      $converter->_convert_1_to_4;
    }
    elsif ( $source_version < 3 ) {
      $converter->_convert_2_to_4;
    }
    elsif ( $source_version < 3.1 ) {
      $converter->_convert_3_to_4;
    } 
    else { #if( $source_version < 4 ) {
        $converter->_convert_3_1_to_4;
    }
    

    # stamp the correct version
    open( my $FH, ">", "$dest_dir/VERSION");
    print $FH "$Data::RecordStore::VERSION\n";
    close $FH;

} #convert

sub _write_data {
  my( $self, $id, $data ) = @_;
  my $osize = do { use bytes; length( $data ); };
  my $size = 5 + $osize;
  my $silo_id = 12;
  if( $size > 4096 ) {
    $silo_id = log( $size ) / log( 2 );
    if( int( $silo_id) < $silo_id ) {
      $silo_id = 1 + int( $silo_id );
    }
  }
  my $idx_silo = $self->{to_index};
  my $to_silo = $self->{to_silos}[$silo_id];
  unless( $to_silo ) {
    my $silo_row_size = 2 ** $silo_id;
    $to_silo = Data::RecordStore::Silo->open_silo( "LZ*", "$self->{dest_dir}/silos/${silo_id}_RECSTORE", $silo_row_size );
    $self->{to_silos}[ $silo_id ] = $to_silo;
  }
  my $to_count = 1 + $to_silo->entry_count;

  $to_silo->_ensure_entry_count( $to_count );
  $to_silo->put_record( $to_count, [ $id, $data ] );

  $idx_silo->_ensure_entry_count( $id );
  $idx_silo->put_record( $id, [ $silo_id, $to_count ] );

} #_silo_id_from_size

sub _convert_1_to_4 {
  my( $self ) = @_;
  my $source_dir = $self->{source_dir};

  my $size_index = Data::RecordStore::Converter::OldSilo->_open( "I", "$source_dir/STORE_INDEX" );
  my $from_index = Data::RecordStore::Converter::OldSilo->_open( "IL", "$source_dir/OBJ_INDEX" );

  my $entries = $from_index->entry_count;

  my( @from_stores );

  for my $id ( 1..$entries ) {
    my $rec = $from_index->get_record( $id );
    my( $silo_id, $idx_in_silo ) = @$rec;

    my $from_silo = $from_stores[$silo_id];
    unless( $from_silo ) {
      my $sz = $size_index->get_record( $silo_id );
      my( $silo_row_size ) = @$sz;
      $from_silo = Data::RecordStore::Converter::OldSilo->_open( "Z*", "$source_dir/${silo_id}_OBJSTORE", $silo_row_size );
      $from_stores[$silo_id] = $from_silo;
    }

    $rec = $from_silo->get_record( $idx_in_silo );
    my( $data ) = @$rec;
    $self->_write_data( $id, $data );
  } #each entry

} #_convert_1_to_4

sub _convert_2_to_4 {
  my( $self ) = @_;
  my $source_dir = $self->{source_dir};

  my $from_index = Data::RecordStore::Converter::OldSilo->_open( "IL", "$source_dir/OBJ_INDEX" );

  my $entries = $from_index->entry_count;

  my( @from_stores );

  for my $id ( 1..$entries ) {
    my $rec = $from_index->get_record( $id );
    my( $silo_id, $idx_in_silo ) = @$rec;
    if( $silo_id ) {
      my $from_silo = $from_stores[$silo_id];
      unless( $from_silo ) {
        my $silo_row_size = int( exp( $silo_id ) );
        $from_silo = Data::RecordStore::Converter::OldSilo->_open( "LZ*", "$source_dir/stores/${silo_id}_OBJSTORE", $silo_row_size );
        $from_stores[$silo_id] = $from_silo;
      }

      $rec = $from_silo->get_record( $idx_in_silo );
      ( undef, my $data ) = @$rec;
      $self->_write_data( $id, $data );
    }
  } #each entry

} #_convert_2_to_4

sub _convert_3_to_4 {
  my( $self ) = @_;
  my $source_dir = $self->{source_dir};

  my $from_index = Data::RecordStore::Silo->open_silo( "IL", "$source_dir/OBJ_INDEX" );

  my $entries = $from_index->entry_count;

  my( @from_stores );

  for my $id ( 1..$entries ) {
    my $rec = $from_index->get_record( $id );
    my( $silo_id, $idx_in_silo ) = @$rec;

    my $from_silo = $from_stores[$silo_id];
    unless( $from_silo ) {
      my $silo_row_size = int( exp( $silo_id ) );
      $from_silo = Data::RecordStore::Silo->open_silo( "LZ*", "$source_dir/silos/${silo_id}_OBJSTORE", $silo_row_size );
      $from_stores[$silo_id] = $from_silo;
    }
    if( $idx_in_silo ) {
      $rec = $from_silo->get_record( $idx_in_silo );
      ( undef, my $data ) = @$rec;
      $self->_write_data( $id, $data );
    }

  } #each entry

} #_convert_3_to_4

sub _convert_3_1_to_4 {
  my( $self ) = @_;
  my $source_dir = $self->{source_dir};

  my $from_index = Data::RecordStore::Silo->open_silo( "IL", "$source_dir/RECORD_INDEX_SILO" );

  my $entries = $from_index->entry_count;

  my( @from_stores );

  for my $id ( 1..$entries ) {
    my $rec = $from_index->get_record( $id );
    my( $silo_id, $idx_in_silo ) = @$rec;
    if( $silo_id) {
      my $from_silo = $from_stores[$silo_id];
      unless( $from_silo ) {
        my $silo_row_size = int( exp( $silo_id ) );
        $from_silo = Data::RecordStore::Silo->open_silo( "LIZ*", "$source_dir/silos/${silo_id}_RECSTORE", $silo_row_size );
        $from_stores[$silo_id] = $from_silo;
      }
      $rec = $from_silo->get_record( $idx_in_silo );
      ( undef, my $uue, my $data ) = @$rec;
      if ( $uue ) {
        $data = unpack 'u', $data;
      }
    
      $self->_write_data( $id, $data );
    }

  } #each entry

} #_convert_3_1_to_4

1;

__END__

VERSIONS
  
 4)  RECORD_INDEX_SILO - IL (silo_id, idx_in_silo)
     silos/${silo_id}_RECSTORE - LZ (record id, record data)
     VERSION
     * store size = 2 ** silo_id, min size 4096

 3.1)RECORD_INDEX_SILO - IL (silo_id, idx_in_silo)
     silos/${silo_id}_RECSTORE - LIZ (record id, uuencode bit, record data)
     VERSION
     * store size = exp silo_id

 3)  RECORD_INDEX_SILO - IL (silo_id, idx_in_silo)
     silos/${silo_id}_RECSTORE - LZ (record id, record data)
     VERSION
     * store size = exp silo_id


 2)  OBJ_INDEX - IL (silo_id, idx_in_silo)
     stores/${silo_id} - LZ (record id, record data)
     VERSION
     * store size = exp silo_id

 1) 
     STORE_INDEX - I (store size)
     OBJ_INDEX   - IL (silo_id, idx_in_silo)
     ${silo_id}_OBJSTORE - LZ (record id, record data)
     VERSION?
