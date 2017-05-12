use utf8;
use strict;
use warnings;

package DR::Tnt::LowLevel;
use Mouse;


has connector_class =>
    is      => 'ro',
    isa     => 'Str',
    default => 'DR::Tnt::LowLevel::Connector::Sync';

has connector   =>
    is              => 'ro',
    isa             => 'DR::Tnt::LowLevel::Connector',
    lazy            => 1,
    builder         => sub {
        my ($self) = @_;
        $self->connector_class->new(
            host        => $self->host,
            port        => $self->port,
            user        => $self->user,
            password    => $self->password,
            utf8        => $self->utf8,
        );
    },
    handles => [
        'connect',
        'handshake',
        'send_request',
        'wait_response',
    ]
;

has host                => is => 'ro', isa => 'Str', required => 1;
has port                => is => 'ro', isa => 'Str', required => 1;
has user                => is => 'ro', isa => 'Maybe[Str]';
has password            => is => 'ro', isa => 'Maybe[Str]';
has utf8                => is => 'ro', isa => 'Bool', default => 1;

__PACKAGE__->meta->make_immutable;
