#!perl

use strict;use warnings;
$SIG{TERM} = sub { print STDERR "long_running_thing_test_thing.pl($$): caught TERM\n"; };
my $ct = 30;
while($ct--) {
    print STDERR "long_running_thing_test_thing.pl($$): \$ct=$ct\n";
    sleep 1;
}
