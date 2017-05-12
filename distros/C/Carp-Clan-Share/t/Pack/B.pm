package t::Pack::B;

use strict;
use warnings;

use t::Pack::Carp;
#use Carp::Clan qw/^t::Pack:: verbose/;

sub b {
    croak "Break!";
}

1;
