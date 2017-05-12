package Autocache::Strategy::Store::Memory;

use Any::Moose;

extends 'Autocache::Strategy';

use Autocache::Logger qw(get_logger);

has '_cache' => (
    is => 'rw',
    default => sub { {} },
    init_arg => undef,
);

#
# get REQ
#
sub get
{
    my ($self,$req) = @_;
    get_logger()->debug( "get: " . $req->key );
    return unless exists $self->_cache->{$req->key};
    return $self->_cache->{$req->key};
}

#
# set REQ REC
#
sub set
{
    my ($self,$req,$rec) = @_;
    get_logger()->debug( "set: " . $req->key );
    $self->_cache->{$req->key} = $rec;
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete: $key" );
    delete $self->_cache->{$key};
}

#
# clear
#
sub clear
{
    my ($self,$key) = @_;
    get_logger()->debug( "clear" );
    $self->_cache = {};
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    return $class->$orig();
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
