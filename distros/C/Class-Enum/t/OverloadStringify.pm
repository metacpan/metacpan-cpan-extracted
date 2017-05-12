package t::OverloadStringify;
use strict;
use warnings;

use Class::Enum qw(false true),
    -overload => { '""' => sub { $_[0]->ordinal } };

1;
