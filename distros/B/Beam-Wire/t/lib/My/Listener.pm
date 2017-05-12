package
    My::Listener;

use Moo;

our $LAST_CREATED;

sub BUILD {
    $LAST_CREATED = $_[0];
}

has events_seen => (
    is => 'rw',
    default => sub { 0 },
);

has attribute => (
    is => 'ro',
);

sub on_greet {
    my ( $self ) = @_;
    $self->events_seen( $self->events_seen + 1 );
    return;
}

1;
