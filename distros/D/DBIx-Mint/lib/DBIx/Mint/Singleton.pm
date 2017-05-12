package DBIx::Mint::Singleton;

use Carp;
use Moo;
with 'MooX::Singleton';

has pool => (is => 'rw', default => sub { {} } );

sub add_instance {
    my ($self, $mint) = @_;
    if (exists $self->pool->{$mint->name}) {
        $mint = $self->pool->{$mint->name};
    }
    else {
        $self->pool->{$mint->name} = $mint;
    }
    return $mint;
}

sub get_instance {
    my ($self, $name) = @_;
    return exists $self->pool->{$name} ?
        $self->pool->{$name} : undef;
}

sub exists {
    my ($self, $name) =  @_;
    return exists $self->pool->{$name};
}

1;
