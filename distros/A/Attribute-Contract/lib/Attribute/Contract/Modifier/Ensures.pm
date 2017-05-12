package Attribute::Contract::Modifier::Ensures;

use strict;
use warnings;

require Carp;
use Attribute::Contract::Utils;

sub modify {
    my $class = shift;
    my ($package, $name, $code_ref, $import, $attributes) = @_;

    Carp::croak('Return type(s) are required') unless $attributes;

    my $check = build_check(@_);

    sub {
        my @return = $code_ref->(@_);

        $check->(@return);

        @return;
    };
}

1;
