package Dog;
use Moose;

has Name  => (is => 'ro', isa => 'Str');
has Age   => (is => 'ro', isa => 'Num');
has State => (is => 'ro', isa => 'Str');

sub make_noise {
    my $self = shift;
    say $self->name(), " says: ruff-ruff!";
}

__PACKAGE__->meta->make_immutable;

1;
