package Crypt::Perl::X::ECDSA::NoCurveForNISTName;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $nist_name) = @_;

    return $class->SUPER::new( "This library has no curve for the NIST name “$nist_name”.", { name => $nist_name } );
}

1;
