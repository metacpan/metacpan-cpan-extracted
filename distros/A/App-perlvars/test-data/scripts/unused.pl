use strict;
use warnings;

my $shared = 1;

my $handler = sub {
    my $unused_in_anon;
    return $shared;
};

sub run {
    my $unused_in_named;
    return $handler->();
}

run();
