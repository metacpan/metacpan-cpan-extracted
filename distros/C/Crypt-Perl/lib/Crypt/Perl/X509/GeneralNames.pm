package Crypt::Perl::X509::GeneralNames;

use strict;
use warnings;

use parent qw( Crypt::Perl::ASN1::Encodee );

use Crypt::Perl::X509::GeneralName ();

use constant ASN1 => Crypt::Perl::X509::GeneralName::ASN1() . <<END;
    GeneralNames ::= SEQUENCE OF ANY    -- GeneralName
END

sub new {
    my ($class, @type_vals) = @_;

    my @sequence;

    # Accept either pairs of two-member arrays (new, preferred format)
    # or flat key/value pairs.
    while (@type_vals) {
        if ('ARRAY' eq ref $type_vals[0]) {
            push @sequence, shift @type_vals;
        }
        elsif ( !ref $type_vals[0] ) {
            push @sequence, [ shift(@type_vals) => shift(@type_vals) ];
        }
    }

    return bless \@sequence, $class;
}

sub _encode_params {
    my ($self) = @_;

    my @params = @$self;
    $_ = Crypt::Perl::X509::GeneralName->new(@$_) for @params;

    return [ map { $_->encode() } @params ];
}

1;
