package Consul::Session;
$Consul::Session::VERSION = '0.021';
use namespace::autoclean;

use Moo;
use Types::Standard qw(Str ArrayRef Enum);
use Carp qw(croak);
use JSON::MaybeXS;

has name       => ( is => 'ro', isa => Str );
has behavior   => ( is => 'ro', isa => Enum[qw(release delete)] );
has ttl        => ( is => 'ro', isa => Str );
has node       => ( is => 'ro', isa => Str );
has checks     => ( is => 'ro', isa => ArrayRef[Str] );
has lock_delay => ( is => 'ro', isa => Str );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        defined $self->lock_delay ? ( LockDelay => $self->lock_delay ) : (),
        defined $self->node       ? ( Node      => $self->node )       : (),
        defined $self->name       ? ( Name      => $self->name )       : (),
        defined $self->checks     ? ( Checks    => $self->checks )     : (),
        defined $self->behavior   ? ( Behavior  => $self->behavior )   : (),
        defined $self->ttl        ? ( TTL       => $self->ttl )        : (),
    });
}

1;
