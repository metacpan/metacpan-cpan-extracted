package Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $curve_name) = @_;

    if ($curve_name) {
        return $class->SUPER::new( "This library does not support ECDSA curves that use Characteristic-2 fields, like “$curve_name”.", { curve_name => $curve_name } );
    }

    return $class->SUPER::new( "This library does not support ECDSA curves that use Characteristic-2 fields." );
}

1;
