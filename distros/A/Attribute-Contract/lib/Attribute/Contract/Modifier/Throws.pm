package Attribute::Contract::Modifier::Throws;

use strict;
use warnings;

require Carp;
require Scalar::Util;

use Attribute::Contract::TypeValidator;

my %cache = ();

sub modify {
    my $class = shift;
    my ($package, $name, $code_ref, $attributes) = @_;

    Carp::croak('At least one ISA is required')
      unless $attributes;

    my @isa = split /,/, $attributes;

    sub {
        eval {
            $code_ref->(@_);
        } || do {
            my $e = $@;

            foreach my $isa (@isa) {
                if (Scalar::Util::blessed($e) && $e->isa($isa)) {
                    die $e;
                }
            }

            Carp::croak("Unknown exception: " . ref($e));
        };
    };
}

1;
