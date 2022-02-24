package Local::NoUnused;

use strict;
use warnings;

my $foo;

sub bar {
    my $four = 4;    # this probably should trigger an error
}

1;
