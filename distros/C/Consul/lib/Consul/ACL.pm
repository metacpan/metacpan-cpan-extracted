package Consul::ACL;
$Consul::ACL::VERSION = '0.022';
use namespace::autoclean;

use Moo;
use Types::Standard qw(Str);
use Carp qw(croak);
use JSON::MaybeXS;

has name                => ( is => 'ro', isa => Str );
has id                  => ( is => 'ro', isa => Str );
has type                => ( is => 'ro', isa => Str );
has rules               => ( is => 'ro', isa => Str );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        defined $self->name      ? ( Name     => $self->name     ) : (),
        defined $self->id        ? ( ID       => $self->id       ) : (),
        defined $self->type      ? ( Type     => $self->type     ) : (),
        defined $self->rules     ? ( Rules    => $self->rules    ) : (),
    });
}

1;
