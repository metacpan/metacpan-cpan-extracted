package t::Bag::A;

use strict;
use warnings;

use t::Bag::Carp;

sub a {
    &t::Bag::B::b;
}

sub b {
    croak "Break!";
}

1;
