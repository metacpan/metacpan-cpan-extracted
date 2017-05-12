package t::OverrideDefaultProperties;
use strict;
use warnings;

use Class::Enum (
    Left   => { name => 'L', ordinal => -1 },
    Center => { name => 'C' },
    Right  => { name => 'R' },
);

1;
