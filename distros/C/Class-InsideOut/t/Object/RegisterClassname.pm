package t::Object::RegisterClassname;
use strict;

use Class::InsideOut;

sub new {
    Class::InsideOut::register( shift );
}

1;
