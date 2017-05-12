package TestApp::Service::ExceptClass;
use Moose;
use Carp;

has 'count' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {
        0;
    }
);

has 'id' => ( is => 'rw', );

no Moose;

sub counter {
    my $self = shift;
    $self->count($self->count + 1);
    return $self->count;
}

sub id {
    my $self = shift;
    return $self->id;
}

__PACKAGE__->meta->make_immutable;

1;
