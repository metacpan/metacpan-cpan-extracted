package TestApp::Logic::AnotherClass;
use Moose;

has 'count' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {
        0;
    }
);

has 'uid' => ( is => 'rw', );

no Moose;

sub incr {
    my $self = shift;
    $self->count($self->count + 1);
    return $self->count;
}

__PACKAGE__->meta->make_immutable;

1;
