package Authen::Simple::Fake;

use base 'Authen::Simple::Adapter';

sub check {
    my( $self, $user, $password ) = @_;

    return( $user eq 'root' and $password eq 'god' );
}

1;
