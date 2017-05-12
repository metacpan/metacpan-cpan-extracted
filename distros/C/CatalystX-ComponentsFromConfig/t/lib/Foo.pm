package Foo;
use Moose;

has something => ( is => 'rw' );
has callback => (is => 'ro');
has orig_args => (is => 'ro');

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my @orig_args = @_;
    my $parsed_args = $class->$orig(@_);
    return { %{$parsed_args}, orig_args => \@orig_args };
};

sub doit {
    my ($self) = @_;

    if ($self->callback) {
        $self->callback->($self->something);
    }
}

1;
