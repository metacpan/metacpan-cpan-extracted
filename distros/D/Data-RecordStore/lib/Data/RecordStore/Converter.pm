package Data::RecordStore::Converter;

use strict;
use warnings;

use Data::RecordStore;

use File::Copy::Recursive qw( dircopy dirmove );
use File::Path qw(remove_tree);


=head2 Data::RecordStore::Converter->convert( $source_dir, $dest_dir )

Analyzes the source directory to find version
then creates a new version of the store in the
destination directory.

=cut
sub convert {
    my( $cls, $source_dir, $dest_dir, %args ) = @_;

    die "Data::RecordStore::Converter->convert must be given a destination directory" unless $dest_dir;

    die "Data::RecordStore::Converter->convert must be given a source directory" unless $source_dir;

    die "Data::RecordStore::Converter->convert : cannot find source directory '$source_dir'" unless -d $source_dir;
    
    if( -d $dest_dir && -e "$dest_dir/VERSION" ) {
        die "Data::RecordStore::Converter->convert  : Destination directory '$dest_dir' already exists";
    }

    my $source_version = Data::RecordStore->detect_version( $source_dir );

    my $rs_pkg;
    if( ! defined $source_version ) {
        die "No store found in $source_dir";
    }
    if ( $source_version < 2 ) {
        $rs_pkg = 'RS_1';
    }
    elsif ( $source_version < 3 ) {
        $rs_pkg = 'RS_2';
    }
    elsif ( $source_version < 3.1 ) {
        $rs_pkg = 'RS_3';
    } 
    elsif( $source_version < 4 ) {
        $rs_pkg = 'RS_3_1';
    }
    elsif( $source_version < 5 ) {
        $rs_pkg = 'RS_4';
    }
    else { #elsif( $source_version < 6 ) {
        $rs_pkg = 'RS_5';
    }

    my $old_rs = $rs_pkg->open( $source_dir );

    $args{BASE_PATH} = $dest_dir;

    my $new_rs = Data::RecordStore->open_store( %args );

    my $entries = $old_rs->entry_count;
    for my $id (1..$entries) {
        my $val = $old_rs->fetch( $id );
        $new_rs->stow( $val );
    }
    
} #convert

package RS_1;

sub open {
    my( $cls, $dir ) = @_;
    my $store_idx = SiloPre3->open( "$dir/STORE_INDEX", "I" );
    my $count = $store_idx->entry_count;
    return bless {
        count       => $count,
        index_silo  => SiloPre3->open( "$dir/OBJ_INDEX", "IL" ), 
        entry_silos => [ map { SiloPre3->open( "$dir/${_}_OBJSTORE", "A*", $store_idx->get_record($_)->[0] ) } (1..$count) ]
    }, $cls;
}
sub entry_count {
    return shift->{index_silo}->entry_count;
}
sub fetch {
    my( $self, $idx ) = @_;
    my $lookup = $self->{index_silo}->get_record( $idx );
    my( $silo_id, $idx_in_silo ) = @$lookup;
    my $silo = $self->{entry_silos}[$silo_id - 1];
    my $result = $silo->get_record( $idx_in_silo );
    return $result->[0];
}

package RS_2;

sub open {
    my( $cls, $dir ) = @_;

    opendir( my $dh, "$dir/stores/" );
    my( @silo_ids ) = map { s/_OBJSTORE//; $_ } grep { /\d+_OBJSTORE/ }  readdir( $dh );
    closedir $dh;
    
    return bless {
        index_silo  => SiloPre3->open( "$dir/OBJ_INDEX", "IL" ), 
        entry_silos => { map { $_ => SiloPre3->open( "$dir/stores/${_}_OBJSTORE", "LA*", int( exp( $_) ) ) } (@silo_ids)}
    }, $cls;
}
sub entry_count {
    return shift->{index_silo}->entry_count;
}
sub fetch {
    my( $self, $idx ) = @_;
    my $lookup = $self->{index_silo}->get_record( $idx );
    my( $silo_id, $id_in_silo ) = @$lookup;
    return undef unless $silo_id;
    my $silo = $self->{entry_silos}{$silo_id};
    my $result = $silo->get_record( $id_in_silo );
    return $result->[1];
}

package RS_3;

sub open {
    my( $cls, $dir ) = @_;

    opendir( my $dh, "$dir/silos/" );
    my( @silo_ids ) = map { s/_OBJSTORE//; $_ } grep { /\d+_OBJSTORE/ }  readdir( $dh );
    closedir $dh;
    
    return bless {
        index_silo  => Silo3_and_later->open_silo( "IL", "$dir/OBJ_INDEX" ), 
        entry_silos => { map { $_ => Silo3_and_later->open_silo( "LZ*", "$dir/silos/${_}_OBJSTORE", int( exp( $_) ) ) } (@silo_ids) }
    }, $cls;
}
sub entry_count {
    return shift->{index_silo}->entry_count;
}
sub fetch {
    my( $self, $idx ) = @_;
    my $lookup = $self->{index_silo}->get_record( $idx );
    my( $silo_id, $id_in_silo ) = @$lookup;
    return undef unless $silo_id;
    my $silo = $self->{entry_silos}{$silo_id};
    my $result = $silo->get_record( $id_in_silo );
    return $result->[1];
}

package RS_3_1;

sub open {
    my( $cls, $dir ) = @_;

    opendir( my $dh, "$dir/silos/" );
    my( @silo_ids ) = map { s/_RECSTORE//; $_ } grep { /\d+_RECSTORE/ }  readdir( $dh );
    closedir $dh;
    
    return bless {
        index_silo  => Silo3_and_later->open_silo( "IL", "$dir/RECORD_INDEX_SILO" ), 
        entry_silos => { map { $_ => Silo3_and_later->open_silo( "LIA*", "$dir/silos/${_}_RECSTORE", int( exp( $_) ) ) } (@silo_ids) }
    }, $cls;
}
sub entry_count {
    return shift->{index_silo}->entry_count;
}
sub fetch {
    my( $self, $idx ) = @_;
    my $lookup = $self->{index_silo}->get_record( $idx );
    my( $silo_id, $id_in_silo ) = @$lookup;
    return undef unless $silo_id;
    my $silo = $self->{entry_silos}{$silo_id};
    my $result = $silo->get_record( $id_in_silo );
    if( $result->[1] ) {
        my $ret = unpack 'u', $result->[2];
        chop $ret; #seems that included an extra byte :(
        return $ret;
    }
    return $result->[2];
}

package RS_4;

sub open {
    my( $cls, $dir ) = @_;

    opendir( my $dh, "$dir/silos/" );
    my( @silo_ids ) = map { s/_RECSTORE//; $_ } grep { /\d+_RECSTORE/ }  readdir( $dh );
    closedir $dh;

    return bless {
        index_silo  => Silo3_and_later->open_silo( "IL", "$dir/RECORD_INDEX_SILO" ), 
        entry_silos => { map { $_ => Silo3_and_later->open_silo( "LA*", "$dir/silos/${_}_RECSTORE", 2 ** $_ ) } (@silo_ids) }
    }, $cls;
}
sub entry_count {
    return shift->{index_silo}->entry_count;
}
sub fetch {
    my( $self, $idx ) = @_;
    my $lookup = $self->{index_silo}->get_record( $idx );
    my( $silo_id, $id_in_silo ) = @$lookup;
    return undef unless $silo_id;
    my $silo = $self->{entry_silos}{$silo_id};
    my $result = $silo->get_record( $id_in_silo );
    return $result->[1];
}


package RS_5;

sub open {
    my( $cls, $dir ) = @_;
    
    opendir( my $dh, "$dir/silos/" );
    my( @silo_ids ) = map { s/_RECSTORE//; $_ } grep { /\d+_RECSTORE/ }  readdir( $dh );
    closedir $dh;
    
    return bless {
        index_silo  => Silo3_and_later->open_silo( "ILL", "$dir/RECORD_INDEX_SILO" ), 
        entry_silos => { map { $_ => Silo3_and_later->open_silo( "LA*", "$dir/silos/${_}_RECSTORE", 2 ** $_ ) } (@silo_ids) },
    }, $cls;
}
sub entry_count {
    return shift->{index_silo}->entry_count;
}
sub fetch {
    my( $self, $idx ) = @_;
    my $lookup = $self->{index_silo}->get_record( $idx );
    my( $silo_id, $id_in_silo ) = @$lookup;
    return undef unless $silo_id;
    my $silo = $self->{entry_silos}{$silo_id};
    my $result = $silo->get_record( $id_in_silo );
    return $result->[1];
}

package RS_6;



package Silo3_and_later;

use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use Fcntl qw( SEEK_SET );
use File::Path qw(make_path remove_tree);

use constant {
    DIRECTORY        => 0,
    RECORD_SIZE      => 1,
    FILE_SIZE        => 2,
    FILE_MAX_RECORDS => 3,
    TMPL             => 4,
};

# this really isn't much of a limit anymore, but...
# keeping it for now
$Silo3_and_later::MAX_SIZE = 2_000_000_000;


sub open_silo {
    my( $class, $template, $directory, $size ) = @_;

    my $record_size = $size;
    if( $record_size == 0 ) {
        $record_size = do { use bytes; length( pack( $template ) ) };
    }
    my $file_max_records = int( $Silo3_and_later::MAX_SIZE / $record_size );
    my $file_max_size = $file_max_records * $record_size;

    my $silo = bless [
        $directory,
        $record_size,
        $file_max_size,
        $file_max_records,
        $template,
        ], $class;

    return $silo;
} #open_silo

sub entry_count {
    # return how many entries this silo has
    my $self = shift;
    my @files = $self->_files;
    my $filesize;
    for my $file (@files) {
        $filesize += -s "$self->[DIRECTORY]/$file";
    }
    return int( $filesize / $self->[RECORD_SIZE] );
} #entry_count

sub get_record {
    my( $self, $id ) = @_;

    my( $f_idx, $fh, $file, $file_id ) = $self->_fh( $id, 'readonly' );

    sysseek( $fh, $self->[RECORD_SIZE] * $f_idx, SEEK_SET );
    my $srv = sysread $fh, my $data, $self->[RECORD_SIZE];
    close $fh;

    return [unpack( $self->[TMPL], $data )];
} #get_record

#
# Takes an insertion id and returns
#   an insertion index for in the file
#   filehandle.
#   filepath/filename
#   which number file this is (0 is the first)
#
sub _fh {
    my( $self, $id ) = @_;
    my @files = $self->_files;

    my $f_idx = int( ($id-1) / $self->[FILE_MAX_RECORDS] );

    my $file = $files[$f_idx];
    my $fh;
    open( $fh, "<", "$self->[DIRECTORY]/$file" );
    return (($id - ($f_idx*$self->[FILE_MAX_RECORDS])) - 1,$fh,"$self->[DIRECTORY]/$file",$f_idx);
} #_fh

#
# Returns the list of filenames of the 'silos' of this store. They are numbers starting with 0
#
sub _files {
    my $self = shift;
    opendir( my $dh, $self->[DIRECTORY] );
    my( @files ) = (
        sort { $a <=> $b }
        grep { /\d+/ }
        readdir( $dh ) );
    closedir $dh;
    return @files;
} #_files

# ----------- end Silo3_and_later

package SiloPre3;

#
# This package is a helper one that simulates
# older silo formats before version 3.1
#

use strict;
use warnings;
no warnings 'uninitialized';

use Fcntl qw( SEEK_SET );

sub open {
    my( $class, $filename, $template, $size ) = @_;
    my $useSize = $size;
    if( ! $useSize ) {
      $useSize = do { use bytes; length( pack( $template ) ) };
    }
    bless { TMPL        => $template, 
            RECORD_SIZE => $useSize,
            FILENAME    => $filename,
    }, $class;
} #open

sub entry_count {
    my $self = shift;
    my $filesize = -s $self->{FILENAME};
    return int( $filesize / $self->{RECORD_SIZE} );
}

sub get_record {
    my( $self, $id ) = @_;

    my $fh = $self->_filehandle;
    sysseek $fh, $self->{RECORD_SIZE} * ($id-1), SEEK_SET;
    sysread $fh, my $data, $self->{RECORD_SIZE};
    close $fh;
    return [unpack( $self->{TMPL}, $data )];
} #get_record

sub _filehandle {
    my $self = shift;
    CORE::open( my $fh, "<", $self->{FILENAME} );
    return $fh;
}




"You can't work in a steel mill and think small. Giant converters hundreds of feet high. Every night, the sky looked enormous. It was a torrent of flames - of fire. The place that Pittsburgh used to be had such scale -  Jack Gilbert";

__END__

VERSIONS

 6)  RECORD_INDEX_SILO - ILL (silo_id, idx_in_silo, last_updated_timestamp)
     data_silos/${silo_id} - ILLa* (status, id, data-length, data )
     VERSION
     LOCK
     RINFO
     * store size = 2 ** silo_id, min size 4096

 5)  RECORD_INDEX_SILO - ILL (silo_id, idx_in_silo, last_updated_timestamp)
     silos/${silo_id}_RECSTORE - LZ (record id, record data)
     VERSION
     * store size = 2 ** silo_id, min size 4096

  
 4)  RECORD_INDEX_SILO - IL (silo_id, idx_in_silo)
     silos/${silo_id}_RECSTORE - LZ (record id, record data)
     VERSION
     * store size = 2 ** silo_id, min size 4096

 3.1)RECORD_INDEX_SILO - IL (silo_id, idx_in_silo)
     silos/${silo_id}_RECSTORE - LIZ (record id, uuencode bit, record data)
     VERSION
     * store size = exp silo_id

 3)  OBJ_INDEX - IL (silo_id, idx_in_silo)
     silos/${silo_id}_RECSTORE - LZ (record id, record data)
     VERSION
     * store size = exp silo_id
     - introduces subsilos. Silo file max size 2_000_000_000

 2)  OBJ_INDEX - IL (silo_id, idx_in_silo)
     stores/${silo_id}_OBJSTORE - LZ (record id, record data)
     VERSION
     * store size = exp silo_id

 1) 
     STORE_INDEX - I (store size)
     OBJ_INDEX   - IL (silo_id, idx_in_silo)
     ${silo_id}_OBJSTORE - Z (record data)
     VERSION?
