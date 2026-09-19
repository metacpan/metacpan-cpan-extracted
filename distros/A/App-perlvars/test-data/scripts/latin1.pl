use strict;
use warnings;

# Cookie value with a Latin-1 byte: å

sub run {
    my $unused_latin1;
    return 1;
}

run();
