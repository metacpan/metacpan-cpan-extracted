package Crypt::RSA::Parse::Public;

use parent qw(Crypt::RSA::Parse::KeyBase);

use parent qw(Class::Accessor::Fast);

BEGIN {
    __PACKAGE__->mk_ro_accessors('exponent');

    *E = \&exponent;
}

1;
