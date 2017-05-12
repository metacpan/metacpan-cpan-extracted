package # hide from PAUSE
    Test::Class::Load;

use strict;
use warnings;

use Class::Load::XS;

$ENV{CLASS_LOAD_IMPLEMENTATION} = 'XS';

require Class::Load;

sub import {
    Class::Load->export_to_level(1, @_);
}

1;
