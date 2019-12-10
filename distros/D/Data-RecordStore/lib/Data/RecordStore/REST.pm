package Data::RecordStore::REST;

use strict;
use warnings;

our $REC_STORE;

sub init {
    my( $cls ) = @_;
    my $root_dir = $ENV{RECORD_STORE_ROOT} || '/opt/recordstore';
    my $cfg = YAML::LoadFile( "$root_dir/record-store-conf.yaml" );
    my $rs_class = $cfg->{CLASS};
    require "$rs_class.pm";
    $REC_STORE = $rs_class->open_store( %{$cfg->{OPTIONS}} );
    return $REC_STORE;
} #init

sub handle {
    my( $cls, $action, $id, $data ) = @_;
    $REC_STORE //= $cls->init;
    if( $action eq 'next_id' ) {
        return $REC_STORE->next_id;
    }
    elsif( $action eq 'stow' ) {
        $id //= $REC_STORE->next_id;
        return $REC_STORE->stow( $data, $id );
    }
    elsif( $action eq 'fetch' && $id ) {
        return $REC_STORE->fetch( $id );
    }
    elsif( $action eq 'delete_record' && $id ) {
        return $REC_STORE->delete_record( $id );
    }
    if( length( $data ) > 100 ) {
        $data = substr($data,0,100).'...';
    }
    die "Unable to peform action '$action' with id '$id' and data '$data'\n";
}

sub lock {
    
}

sub unlock {

}

sub stow {

}

sub fetch {

}

sub delete_record {

}

sub has_id {

}

sub next_id {

}

sub empty {

}

sub size {

}

sub entry_count {

}

sub record_count {

}


"Meet the new boss Same as the old boss - The Who";
