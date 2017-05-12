package TImport;

use strict;
use warnings;

use FooExport qw(this that);
use Class::Trait 'base';

sub getName {
    return "TImport";
}

1;
