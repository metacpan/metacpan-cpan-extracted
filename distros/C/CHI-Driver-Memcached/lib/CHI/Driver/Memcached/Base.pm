package CHI::Driver::Memcached::Base;
$CHI::Driver::Memcached::Base::VERSION = '0.16';
use CHI;
use Carp;
use Class::Load;
use Moose;
use strict;
use warnings;

has 'memd'        => ( is => 'ro', init_arg => undef );
has 'memd_class'  => ( is => 'ro' );
has 'memd_params' => ( is => 'ro' );

extends 'CHI::Driver::Base::CacheContainer';

# Unsupported methods
#
__PACKAGE__->declare_unsupported_methods(
    qw(dump_as_hash get_keys get_namespaces is_empty clear purge));

__PACKAGE__->meta->make_immutable();

sub BUILD {
    my ( $self, $params ) = @_;

    $self->{memd_params} ||= $self->non_common_constructor_params($params);
    $self->{memd_params}->{namespace} ||= $self->{namespace} . ":";
    $self->{memd} = $self->{_contained_cache} = $self->_build_contained_cache;
    $self->{max_key_length} = 248 - length( $self->{namespace} )
      if !defined( $self->{max_key_length} );
}

sub _build_contained_cache {
    my ($self) = @_;

    Class::Load::load_class( $self->memd_class );
    return $self->memd_class->new( $self->memd_params );
}

# Memcached supports fast multiple get
#

sub fetch_multi_hashref {
    my ( $self, $keys ) = @_;
    croak "must specify keys" unless defined($keys);

    return $self->memd->get_multi(@$keys);
}

1;
