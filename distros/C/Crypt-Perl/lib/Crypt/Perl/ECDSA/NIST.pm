package Crypt::Perl::ECDSA::NIST;

use strict;
use warnings;

use Symbol::Get ();

use Crypt::Perl::X ();

use constant JWK_CURVE_prime256v1 => 'P-256';
use constant JWK_CURVE_secp384r1 => 'P-384';
use constant JWK_CURVE_secp521r1 => 'P-521';

sub get_nist_for_curve_name {
    my ($curve_name) = @_;

    die Crypt::Perl::X::create('Generic', 'Need curve name!') if !length $curve_name;

    my $cr = __PACKAGE__->can("JWK_CURVE_$curve_name") or do {
        die Crypt::Perl::X::create('ECDSA::NoCurveForName', { name => $curve_name });
    };

    return $cr->();
}

sub get_curve_name_for_nist {
    my ($nist_name) = @_;

    die Crypt::Perl::X::create('Generic', 'Need NIST curve name!') if !length $nist_name;

    for my $node ( Symbol::Get::get_names() ) {
        next if $node !~ m<\AJWK_CURVE_(.+)>;

        my $nist = __PACKAGE__->can($node)->();
        return $1 if $nist eq $nist_name;
    }

    die Crypt::Perl::X::create('ECDSA::NoCurveForNISTName', { name => $nist_name });
}

1;
