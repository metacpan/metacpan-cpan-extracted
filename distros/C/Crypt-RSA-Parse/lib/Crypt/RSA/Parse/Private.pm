package Crypt::RSA::Parse::Private;

use parent qw(Crypt::RSA::Parse::KeyBase);

use parent qw(Class::Accessor::Fast);

BEGIN {
    __PACKAGE__->mk_ro_accessors(
        qw(
        version
        publicExponent
        privateExponent
        prime1
        prime2
        exponent1
        exponent2
        coefficient
        )
    );

    *E = \&publicExponent;
    *D = \&privateExponent;

    *P = \&prime1;
    *Q = \&prime2;

    *DP = \&exponent1;
    *DQ = \&exponent2;

    *QINV = \&coefficient;
}

1;
