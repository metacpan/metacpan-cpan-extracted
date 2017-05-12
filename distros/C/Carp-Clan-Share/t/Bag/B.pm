package t::Bag::B;

use strict;
use warnings;

use t::Bag::Carp;
#use Carp::Clan qw/^t::Pack:: verbose/;

sub b {
    croak "Break!";
}

1;
