package Crypt::Perl::X::ECDSA::NoCurveForName;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $name) = @_;

    return $class->SUPER::new( "This library has no curve named “$name”.", { name => $name } );
}

1;
