package t::Object::Trivial;
use strict;

use Class::InsideOut;

sub new {
    Class::InsideOut::register( bless \(my $s), shift);
}

1;
