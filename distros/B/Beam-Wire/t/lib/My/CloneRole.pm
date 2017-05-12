package
    My::CloneRole;

use Moo::Role;

sub clone {
    my ( $self, %args ) = @_;
    return (ref $self)->new( %$self, %args );
}

1;
