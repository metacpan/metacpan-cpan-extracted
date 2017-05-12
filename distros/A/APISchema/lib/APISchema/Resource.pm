package APISchema::Resource;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw => [qw(title definition)],
);

1;
