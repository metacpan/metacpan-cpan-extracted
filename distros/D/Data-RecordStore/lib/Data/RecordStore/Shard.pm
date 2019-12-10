package Data::RecordStore::Shard;

use strict;
use warnings;

use Data::RecordStore;

sub new {
    my( $cls, $id, $config ) = @_;
    my $cfg = $config->{$id};
    my $shards = scalar keys %{$config->{hosts}};
    my $rec_store = Data::RecordStore->open_store( $config->{directory});
    
    return bless {
        rec_store  => $rec_store,
        id         => $id,
        host       => $cfg->{host},
        port       => $cfg->{port},
        shards     => $shards,
        block_size => $config->{block_size},
        hosts      => $config->{hosts},
        config     => $config,
    }, $cls
} #new

sub stow {
    
}

sub fetch {
    
}

sub next_id {
    my $self = shift;
    my $id = $self->{rec_store}->next_id;
    
    my $bucket_overage = $self->id_2_shard - $self->{id};
    
    if( $bucket_overage == 0 ) {
        return $id;
    }
    my $next_chunk = $self->{block_size} * 
}

sub id_2_shard {
    my( $self, $id ) = @_;
    my $buckets = $self->{shards};
    my $hash_part = int( $id / $self->{block_size} );
    my $bucket = $hash_part % $buckets;
    return $bucket;
} #id_2_shard

sub setConfig {
    my( $self, $cfg ) = @_;
    $self->{config} = $cfg;
} #setConfig




"quote about shards";

__DATA__

block_size: 1000
hosts:
  0:
    host: localhost
    port: 8000
    directory: /opt/yote/shard
  1: 
    host: localhost
    port: 8001

__END__

