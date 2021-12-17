package Crypt::Perl::BigInt;

use strict;
use warnings;

# Even though Crypt::Perl intends to be pure Perl, there’s no reason
# not to use faster computation methods when they’re available.
#
#No FastCalc because of bugs shown in the following test runs:
#http://www.cpantesters.org/cpan/report/a03dce70-c698-11e6-a1ce-1a99c671d6e6
#http://www.cpantesters.org/cpan/report/0a3e797e-c693-11e6-8c46-2488c671d6e6

use constant _LTM_IS_OK => eval {
    require CryptX;
    CryptX->VERSION('0.074');
};

use constant _TRY => join(
    ',',
    'GMP',
    ( _LTM_IS_OK ? 'LTM' : () ),
    qw( GMPz Pari BitVect ),
);

# Sorted in descending order of observed speed:
use Math::BigInt try => _TRY;

#To test pure Perl speed, comment out the above and enable:
#use Math::BigInt;

use parent -norequire => 'Math::BigInt';

#There has been some trouble getting GMP and Pari to do from_bytes()
#and as_bytes(), so let’s check on those here.
BEGIN {
    if ( !eval { __PACKAGE__->fffrom_bytes('1234') } ) {
        *from_bytes = \&_pp_from_bytes;
    }

    if ( !eval { __PACKAGE__->new(1234)->aaas_bytes() } ) {
        *as_bytes = \&_pp_as_bytes;
    }

    # Accommodate Math::BigInt::GMP 1.51 …
    if ( !eval { __PACKAGE__->new(1234)->to_bin() } ) {
        *to_bin = \&_pp_to_bin;
    }
    if ( !eval { __PACKAGE__->new(1234)->to_hex() } ) {
        *to_hex = \&_pp_to_hex;
    }

    $@ = q<>;
}

use Crypt::Perl::X ();

sub _pp_to_hex {
    return substr( $_[0]->as_hex(), 2 );
}

sub _pp_from_bytes {
    my $class = shift;

    return $class->from_hex( unpack 'H*', $_[0] );
}

sub _pp_as_bytes {
    my ($self) = @_;

    die Crypt::Perl::X::create('Generic', "Negatives ($self) can’t convert to bytes!") if $self < 0;

    my $hex = $self->as_hex();

    #Ensure that we have an even number of hex digits.
    if (length($hex) % 2) {
        substr($hex, 1, 1) = q<>;   #just remove the “x” of “0x”
    }
    else {
        substr($hex, 0, 2) = q<>;   #remove “0x”
    }

    return pack 'H*', $hex;
}

sub _pp_to_bin {
    my ($self) = @_;

    my $bin = unpack 'B*', $self->as_bytes();
    $bin =~ s<\A0+><>;

    return $bin;
}

sub bit_length {
    my ($self) = @_;

    #Probably faster than 1 + $self->copy()->blog(2) …
    return( length($self->as_bin()) - 2 );
}

sub test_bit {
    my ($self, $bit_from_least) = @_;

    my $bstr = substr( $self->as_bin(), 2 );

    return 0 if $bit_from_least >= length($bstr);

    return substr($bstr, -$bit_from_least - 1, 1);
}

1;
