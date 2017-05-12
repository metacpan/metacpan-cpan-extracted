package Attribute::Contract::Modifier::Requires;

use strict;
use warnings;

require Carp;
use Attribute::Contract::Utils;

sub modify {
    my $class = shift;
    my ($package, $name, $code_ref, $import, $attributes) = @_;

    my $check = build_check(@_);

    sub {
        $code_ref->($check->(@_));
    };
}

1;
