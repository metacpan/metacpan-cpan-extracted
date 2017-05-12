package t::Pack::A;

use strict;
use warnings;

use t::Pack::Carp;

sub a {
    &t::Pack::B::b;
}

sub b {
    croak "Break!";
}

1;
