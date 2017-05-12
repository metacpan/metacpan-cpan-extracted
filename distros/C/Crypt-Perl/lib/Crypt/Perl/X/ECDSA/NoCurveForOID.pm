package Crypt::Perl::X::ECDSA::NoCurveForOID;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $oid) = @_;

    return $class->SUPER::new( "This library has no curve parameters that match the OID “$oid”.", { oid => $oid } );
}

1;
