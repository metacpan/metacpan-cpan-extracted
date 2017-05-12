package Crypt::RSA::Parse::KeyBase;

use parent qw(Class::Accessor::Fast);

BEGIN {
    __PACKAGE__->mk_ro_accessors('modulus');

    *N = \&modulus;
}

sub size {
    my ($self) = @_;

    return length( $self->modulus()->as_bin() ) - 2;
}

1;
