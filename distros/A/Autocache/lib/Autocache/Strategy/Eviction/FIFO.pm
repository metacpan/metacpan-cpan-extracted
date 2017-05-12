package Autocache::Strategy::Eviction::FIFO;

use Any::Moose;

extends 'Autocache::Strategy';

use Carp qw( confess );
use Devel::Size qw( total_size );
use Autocache::Logger qw( get_logger );

has 'size' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'max_size' => (
    is => 'ro',
    isa => 'Int',
    default => 1024,
);

#
# queue of keys as we have seen them set
#
has '_queue' => (
    is => 'rw',
    lazy_build => 1,
);

#
# map of keys to sizes
#
has '_map' => (
    is => 'rw',
    lazy_build => 1,
);

#
# base_strategy : underlying strategy that handles storage and expiry -
# defaults
#
has 'base_strategy' => (
    is => 'ro',
    isa => 'Autocache::Strategy',
    lazy_build => 1,
);

#
# get REQ
#
sub get
{
    my ($self,$req) = @_;
    get_logger()->debug( 'get: ' . $req->key );
    return $self->base_strategy->get( $req )
}

#
# set REQ REC
#
sub set
{
    my ($self,$req,$rec) = @_;
    get_logger()->debug( 'set: ' . $req->key );

    my $size = $self->size;

    my ( $key, $rec_size ) = $self->_remove_entry( $req->key );

    if( $key )
    {
        $size -= $rec_size;
    }

    $key = $req->key;
    $rec_size = total_size( $rec );
    $size += $rec_size;

    while( $size > $self->max_size )
    {
        get_logger()->debug( "cache size: $size" );

        my ( $victim_key, $victim_size ) = $self->_remove_entry;

        get_logger()->debug( "FIFO key: " . $victim_key );

        $size -= $victim_size;
        $self->base_strategy->delete( $victim_key );
    }

    $self->size( $size );
    push @{$self->_queue}, $key;
    $self->_map->{$key} = $rec_size;

    return $self->base_strategy->set( $req, $rec );
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete: $key" );

    my $size = $self->size;

    my ( $removed_key, $rec_size ) = $self->_remove_entry( $key );

    if( $removed_key )
    {
        $size -= $rec_size;
        $self->size( $size );
    }

    my $rec = $self->base_strategy->delete( $key );

    return $rec;
}

#
# clear
#
sub clear
{
    my ($self,$key) = @_;
    get_logger()->debug( "clear" );
    $self->base_strategy->clear;
    $self->_queue = [];
    $self->_map = {};
    $self->size( 0 );
}

#
# _remove_entry [KEY]
#
# remove an entry from our queue and map. returns the key removed and the
# record size. defaults to removing the first item on the queue.
#
sub _remove_entry
{
    my ($self,$key) = @_;
    get_logger()->debug( "_remove_entry" );

    if( scalar @{$self->_queue} )
    {
        # default to first in
        $key ||= $self->_queue->[0];

        if( my $size = delete $self->_map->{$key} )
        {
            @{$self->_queue} = grep { $_ ne $key } @{$self->_queue};
            return wantarray ? ( $key, $size ) : $key;
        }
    }
    return undef;
}

sub _build__queue
{
    return [];
}

sub _build__map
{
    return {};
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $node;

        if( $node = $config->get_node( 'max_size' ) )
        {
            get_logger()->debug( "max_size node found" );
            $args{max_size} = $node->value;
        }

        if( $node = $config->get_node( 'base_strategy' ) )
        {
            get_logger()->debug( "base strategy node found" );
            $args{base_strategy} = Autocache->singleton->get_strategy( $node->value );
        }

        return $class->$orig( %args );
    }
    else
    {
        return $class->$orig(@_);
    }
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
