package Crypt::Perl::ECDSA::ECParameters;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::ECParameters - Parse RFC 3279 explicit curves

=head1 DISCUSSION

This interface is undocumented for now.

=cut

use strict;
use warnings;

use Try::Tiny;

use Crypt::Perl::BigInt ();
use Crypt::Perl::ECDSA::EncodedPoint ();
use Crypt::Perl::ECDSA::Utils ();
use Crypt::Perl::X ();

#NOTE: This needs never to use Crypt::Perl::ECDSA::DB
#so that extract_openssl_curves.pl will work.

use constant {
    OID_ecPublicKey => '1.2.840.10045.2.1',
    OID_prime_field => '1.2.840.10045.1.1',
    OID_characteristic_two_field => '1.2.840.10045.1.2',
};

use constant EXPORTABLE => qw( p a b n h gx gy );

#cf. RFC 3279
use constant ASN1_ECParameters => q<
    Trinomial ::= INTEGER

    Pentanomial ::= SEQUENCE {
        k1  INTEGER,
        k2  INTEGER,
        k3  INTEGER
    }

    FG_Basis_Parameters ::= CHOICE {
        gnBasis NULL,
        tpBasis Trinomial,
        ppBasis Pentanomial
    }

    Characteristic-two ::= SEQUENCE {
        m           INTEGER,
        basis       OBJECT IDENTIFIER,
        parameters  FG_Basis_Parameters
    }

    FG_Field_Parameters ::= CHOICE {
        prime-field         INTEGER,    -- p
        characteristic-two  Characteristic-two
    }

    FieldID ::= SEQUENCE {
        fieldType   OBJECT IDENTIFIER,
        parameters  FG_Field_Parameters
    }

    FieldElement ::= OCTET STRING

    Curve ::= SEQUENCE {
        a           FieldElement,
        b           FieldElement,
        seed        BIT STRING OPTIONAL
    }

    ECPoint ::= OCTET STRING

    ECPVer ::= INTEGER

    -- Look for this.
    ECParameters ::= SEQUENCE {
        version         ECPVer,     -- always 1
        fieldID         FieldID,
        curve           Curve,
        base            ECPoint,    -- generator
        order           INTEGER,    -- n

        -- ECDH needs it; ECDSA doesn’t (RFC 3279, p14)
        cofactor        INTEGER OPTIONAL  -- h
    }
>;

#This must return the same information as
#Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_oid().
#
#It also expects the same structure that Convert::ASN1 parses,
#including array references for BIT STRINGs.
#
sub normalize {
    my ($parsed_or_der) = @_;

    my $params;
    if (ref $parsed_or_der) {
        $params = $parsed_or_der;
    }
    else {
        die Crypt::Perl::X::create('Generic', 'TODO');
    }

    my $field_type = $params->{'fieldID'}{'fieldType'};
    if ($field_type ne OID_prime_field() ) {
        if ($field_type eq OID_characteristic_two_field() ) {
            die Crypt::Perl::X::create('ECDSA::CharacteristicTwoUnsupported');
        }

        die Crypt::Perl::X::create('Generic', "Unknown field type OID: “$field_type”");
    }

    #“seed” isn’t necessary here for calculations (… right??)
    my %curve = (
        p => $params->{'fieldID'}{'parameters'}{'prime-field'},
        a => $params->{'curve'}{'a'},
        b => $params->{'curve'}{'b'},
        n => $params->{'order'},
        h => $params->{'cofactor'},
        seed => $params->{'curve'}{'seed'}[0],
    );

    my @ints_to_upgrade = qw( p n );
    if ( defined $curve{'h'} ) {
        push @ints_to_upgrade, 'h';
    }

    #Ensure that numbers like 0 and 1 are represented as BigInt, too.
    ref || ($_ = Crypt::Perl::BigInt->new($_)) for @curve{@ints_to_upgrade};

    $_ = Crypt::Perl::BigInt->from_bytes($_) for @curve{'a', 'b'};

    #We might receive the base point as compressed, uncompressed, or hybrid.
    #Support all of those formats.
    my $base = Crypt::Perl::ECDSA::EncodedPoint->new($params->{'base'})->get_uncompressed(\%curve);
    @curve{'gx', 'gy'} = Crypt::Perl::ECDSA::Utils::split_G_or_public( $base );

    my @strings_to_upgrade = qw( gx gy );
    if ( defined $curve{'seed'} ) {
        push @strings_to_upgrade, 'seed';
    }

    $_ = Crypt::Perl::BigInt->from_bytes($_) for @curve{@strings_to_upgrade};

    defined($curve{$_}) || delete($curve{$_}) for qw( h seed );

#----------------------------------------------------------------------
#    my $db_params;
#
#    try {
#        $db_params = Crypt::Perl::ECDSA::EC::DB::get_curve_name_by_data(\%curve);
#    }
#    catch {
#        if ( !try { $_->isa('Crypt::Perl::X::ECDSA::NoCurveForParameters') } ) {
#            local $@ = $_;
#            die;
#        }
#    };
#
#    #We only get here if there’s no cofactor
#    #or if the one given is correct.
#    if (!$curve{'h'} && !$db_params) {
#        die Crypt::Perl::X::create('Generic', 'This library currently requires a cofactor (“h”) for custom curves.');
#    }
#----------------------------------------------------------------------

#    if ( $params->{'curve'}{'seed'} ) {
#        $curve{'seed'} = Crypt::Perl::BigInt->from_bytes($params->{'curve'}{'seed'});
#
#        #Make sure that the given seed is either for an unknown curve
#        #or is correct for the given curve.
#
#
#        #_get_db_params_or_undef(\%curve);
#
#        #If it’s a known curve, verify that the seed matches.
#        #if ($db_params) {
#        #    my $seed_hex = unpack 'H*', $params->{'curve'}{'seed'};
#        #
#        #    if ($seed_hex ne $db_params->{'seed'}) {
#        #        Crypt::Perl::X::create('Generic', "Curve parameters match “$curve_name”, but the seed ($seed_hex) does not match expected value ($db_params->{'seed'})");
#        #    }
#        #}
#    }
#
#    if (grep { !defined $curve{$_} } 'h', 'seed') {
#        Module::Load::load('Crypt::Perl::ECDSA::EC::DB');
#
#        #TODO: Would it be worthwhile to support arbitrary curves that don’t
#        #give a cofactor? I’d need to figure out how to determine the
#        #cofactor from the other parameters.
#        my $curve_name = Crypt::Perl::ECDSA::EC::DB::get_curve_name_by_data(\%curve);
#        my $params_hr = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name($curve_name);
#
#        @curve{'h', 'seed'} = @{$params}{'h', 'seed'};
#    }

    return \%curve;
}

#sub _get_db_params_or_undef {
#    my ($curve_hr) = @_;
#
#    my ($curve_name, $params_hr);
#    try {
#        $curve_name = Crypt::Perl::ECDSA::EC::DB::get_curve_name_by_data(\%curve);
#        $params_hr = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name($curve_name);
#    }
#    catch {
#        if ( !try { $_->isa('Crypt::Perl::X::ECDSA::NoCurveForParameters') } ) {
#            local $@ = $_;
#            die;
#        }
#    };
#
#    return $params_hr;
#}

#----------------------------------------------------------------------

sub _asn1 {
    my ($class) = @_;

    return Crypt::Perl::ASN1->new()->prepare($class->ASN1_ECParameters())->find('ECParameters');
}

1;
