package TestCart;

use Moo;
extends 'Dancer2::Plugin::Interchange6::Cart';
use namespace::clean;

has test_attribute => (
    is => 'rw',
);

sub test_method {
}

1;
