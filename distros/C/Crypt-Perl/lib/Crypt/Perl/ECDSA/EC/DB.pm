package Crypt::Perl::ECDSA::EC::DB;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::EC::DB - Interface to this module’s CurvesDB datastore

=head1 SYNOPSIS

    my $oid = Crypt::Perl::ECDSA::EC::DB::get_oid_for_curve_name('prime256v1');

    my $data_hr = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_oid('1.2.840.10045.3.1.7');

    my $name = Crypt::Perl::ECDSA::EC::DB::get_curve_name_by_data(
        p => ...,   #isa Crypt::Perl::BigInt
        a => ...,   #isa Crypt::Perl::BigInt
        b => ...,   #isa Crypt::Perl::BigInt
        n => ...,   #isa Crypt::Perl::BigInt
        h => ...,   #isa Crypt::Perl::BigInt
        gx => ...,   #isa Crypt::Perl::BigInt
        gy => ...,   #isa Crypt::Perl::BigInt
        seed => ..., #isa Crypt::Perl::BigInt, optional
    );

    #The opposite query from the preceding.
    my $data_hr = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name('prime256v1');

=head1 DISCUSSION

This interface is undocumented for now.

=cut

use strict;
use warnings;

use Try::Tiny;

use Crypt::Perl::BigInt ();
use Crypt::Perl::X ();

#----------------------------------------------------------------------
# p = prime
# generator (uncompressed) = \x04 . gx . gy
# n = order
# h = cofactor
#
# a and b fit into the general form for an elliptic curve:
#
#   y^2 = x^3 + ax + b
#----------------------------------------------------------------------

#“h” is determinable from the other curve parameters
#and should not be considered necessary to match.
use constant CURVE_EQUIVALENCY => qw( p a b n gx gy );

use constant GETTER_CURVE_ORDER => ( CURVE_EQUIVALENCY(), 'h', 'seed' );

sub get_oid_for_curve_name {
    my ($name) = @_;

    my $name_alt = $name;
    $name_alt =~ tr<-><_>;

    require Crypt::Perl::ECDSA::EC::CurvesDB;

    my $translator_cr = Crypt::Perl::ECDSA::EC::CurvesDB->can("OID_$name_alt");
    die Crypt::Perl::X::create('ECDSA::NoCurveForName', $name) if !$translator_cr;

    return $translator_cr->();
}

sub get_curve_name_by_data {
    my ($data_hr) = @_;

    my %hex_data = map { $_ => substr( $data_hr->{$_}->as_hex(), 2 ) } keys %$data_hr;

    require Crypt::Perl::ECDSA::EC::CurvesDB;

    my $ns = \%Crypt::Perl::ECDSA::EC::CurvesDB::;

  NS_KEY:
    for my $key ( sort keys %$ns ) {
        next if substr($key, 0, 4) ne 'OID_';

        my $oid;
        if ('SCALAR' eq ref $ns->{$key}) {
            $oid = ${ $ns->{$key} };
        }
        elsif ( *{$ns->{$key}}{'CODE'} ) {
            $oid = $ns->{$key}->();
        }
        else {
            next;
        }

        #Avoid creating extra BigInt objects.
        my $db_hex_data_hr;
        try {
            $db_hex_data_hr = _get_curve_hex_data_by_oid($oid);
        }
        catch {
            if ( !try { $_->isa('Crypt::Perl::X::ECDSA::NoCurveForOID') } ) {
                local $@ = $_;
                die;
            }
        };

        next if !$db_hex_data_hr;  #i.e., if we have no params for the OID

        for my $k ( CURVE_EQUIVALENCY() ) {
            next NS_KEY if $hex_data{$k} ne $db_hex_data_hr->{$k};
        }

        #We got a match!

        my $name = substr($key, 4);  # strip leading “OID_”

        #We store dashes as underscores so we can use the namespace.
        #Hopefully no curve OID name will ever contain an underscore!!
        $name =~ tr<_><->;

        #… but let’s make sure the extras (cofactor and seed) are correct,
        #if given. Note that all curves have cofactor == 1 except secp112r2 and
        #secp128r2, both of which have cofactor == 4.
        #
        for my $k ( qw( h seed ) ) {
            if ( defined $hex_data{$k} && $hex_data{$k} ne $db_hex_data_hr->{$k} ) {
                die Crypt::Perl::X::create('Generic', "Curve parameters match “$name”, but “$k” ($hex_data{$k}) does not match expected value ($db_hex_data_hr->{$k})!");
            }
        }

        return $name;
    }

    die Crypt::Perl::X::create('ECDSA::NoCurveForParameters', %hex_data);
}

sub get_curve_data_by_name {
    my ($name) = @_;

    my $oid = get_oid_for_curve_name($name);

    return get_curve_data_by_oid( $oid );
}

#This returns the same information as
#Crypt::Perl::ECDSA::ECParameters::normalize().
sub get_curve_data_by_oid {
    my ($oid) = @_;

    my $data_hr = _get_curve_hex_data_by_oid($oid);

    $_ = Crypt::Perl::BigInt->from_hex($_) for values %$data_hr;

    return $data_hr;
}

sub _get_curve_hex_data_by_oid {
    my ($oid) = @_;

    my $const = "CURVE_$oid";
    $const =~ tr<.><_>;

    require Crypt::Perl::ECDSA::EC::CurvesDB;

    my $getter_cr = Crypt::Perl::ECDSA::EC::CurvesDB->can($const);
    die Crypt::Perl::X::create('ECDSA::NoCurveForOID', $oid) if !$getter_cr;

    my %data;
    @data{ GETTER_CURVE_ORDER() } = $getter_cr->();

    delete $data{'seed'} if !$data{'seed'};

    return \%data;
}

sub _upgrade_hex_to_bigint {
    my ($data_hr) = @_;

    $_ = Crypt::Perl::BigInt->from_hex($_) for @{$data_hr}{ GETTER_CURVE_ORDER() };

    return;
}

1;
