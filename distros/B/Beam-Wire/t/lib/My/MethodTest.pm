package
    My::MethodTest;

use Moo;
extends 'My::ArgsTest';
use overload
    # Test that services with overloads are handled properly while
    # calling methods.
    'bool' => sub { "" },
    ;

sub dies { die }

sub cons {
    my ( $class, @args ) = @_;
    return $class->new( cons => 1, @args );
}

sub append {
    my ( $self, $append ) = @_;
    $self->got_args->[1] .= '; ' . $append;
    return; # Must not return self
}

# XXX: "chain" should be the only thing
sub chain {
    my ( $self, %args ) = @_;
    return $self->new( text => join "; ", $self->got_args_hash->{text}, $args{text} );
}

1;
