package Crypt::Perl::X::ECDSA::NoCurveForParameters;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, @params) = @_;

    return $class->SUPER::new( "This library has no curve that matches these parameters: [@params]" );
}

1;
