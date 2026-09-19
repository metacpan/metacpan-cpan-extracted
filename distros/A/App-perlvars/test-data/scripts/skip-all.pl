use strict;
use warnings;

use Test::More skip_all => 'this file opts out at compile time';

my $unused_in_named;

sub run {
    my $also_unused;
    return 1;
}

run();
