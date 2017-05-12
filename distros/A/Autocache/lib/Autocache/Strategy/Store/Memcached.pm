package Autocache::Strategy::Store::Memcached;

use Any::Moose;

extends 'Autocache::Strategy';

use Cache::Memcached;
use Autocache::Logger qw(get_logger);

#
# Null Memcached Strategy - never expire, memcached
#

has '_memcached' => (
    is => 'ro',
    init_arg => 'memcached', );

#
# get REQ
#
sub get
{
    my ($self,$req) = @_;
    get_logger()->debug( "get: " . $req->key );
    return $self->_memcached->get( $req->key );
}

#
# set KEY RECORD
#
sub set
{
    my ($self,$req,$rec) = @_;
    get_logger()->debug( "set: " . $req->key );
    $self->_memcached->set( $req->key, $rec, 0 );
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete" );
    $self->_memcached->delete( $key );
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $servers = $config->get_node( 'servers' )->value || '127.0.0.1';
        my @servers = split /\s+/, $servers;
        $args{servers} = \@servers;

        if( $config->get_node( 'compress_threshold' ) )
        {
            $args{compress_threshold} = $config->get_node( 'compress_threshold' )->value;
        }

        return $class->$orig( memcached => Cache::Memcached->new( %args ) );
    }
    else
    {
        return $class->$orig(@_);
    }
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
