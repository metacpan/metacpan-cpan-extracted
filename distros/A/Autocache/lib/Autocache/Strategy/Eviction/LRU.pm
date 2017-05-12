package Autocache::Strategy::Eviction::LRU;

use Any::Moose;

extends 'Autocache::Strategy';

use Autocache::Strategy::Eviction::LRU::Entry;
use Carp qw( confess );
use Devel::Size qw( total_size );
use Heap::Binary;
use Heap::Elem::Ref qw( RefElem );
use Autocache::Logger qw(get_logger);

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

has '_heap' => (
    is => 'rw',
    lazy_build => 1,
);

#
# maps keys onto heap elements
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
    get_logger()->debug( 'get: '.$req->key );

    my $rec = $self->base_strategy->get( $req );

    unless( $rec )
    {
        # check that we don't have an entry for the key that exists in our
        # base strategy
        confess "base strategy contains more records than we are aware of"
            if exists $self->_map->{$req->key};

        return undef;
    }

    my $elem = $self->_map->{$req->key};

    confess "base strategy contains record but our map is unaware of it"
        unless $elem;

    # remove from heap, modify atime and re-add
    $self->_heap->delete( $elem );
    $elem->val->touch;
    $self->_heap->add( $elem );

    return $rec;
}

#
# set REQ REC
#
sub set
{
    my ($self,$req,$rec) = @_;
    get_logger()->debug( "set: $req->key" );
    my $elem = RefElem( Autocache::Strategy::Eviction::LRU::Entry->new(
        key => $req->key,
        size => total_size( $rec ) ) );

    my $size = $self->size + $elem->val->size;

    # remove current entry from heap if we already have one for
    # this key
    if( my $tmp = delete $self->_map->{$req->key} )
    {
        get_logger()->debug( "removing existing value for key" );
        $self->_heap->delete( $tmp );
        $size -= $tmp->val->size;
    }

    while( $size > $self->max_size )
    {
        get_logger()->debug( "cache size: $size" );

        my $lru = $self->_heap->extract_top;

        get_logger()->debug( "LRU key: " . $lru->val->key );

        $size -= $lru->val->size;
        delete $self->_map->{$lru->val->key};
        $self->base_strategy->delete( $lru->val->key );
    }

    $self->size( $size );
    $self->_heap->add( $elem );
    $self->_map->{$req->key} = $elem;
    return $self->base_strategy->set( $req, $rec );
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete: $key" );

    my $elem = delete $self->_map->{$key};

    if( $elem )
    {
        $self->heap->delete( $elem );
        $self->size( $self->size - $elem->val->size );
        my $rec = $self->base_strategy->delete( $key );
        confess "delete found element in LRU but not in base strategy"
            unless $rec;
        return $rec;
    }
    else
    {
        my $rec = $self->base_strategy->delete( $key );
        confess "delete did not find element in LRU but did find it in the base strategy"
            unless $rec;
        return $rec;
    }
}

#
# clear
#
sub clear
{
    my ($self,$key) = @_;
    get_logger()->debug( "clear" );
    $self->base_strategy->clear;
    $self->_heap = Heap::Binary->new;
    $self->_map = {};
    $self->size( 0 );
}

sub _build__heap
{
    return Heap::Binary->new;
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
