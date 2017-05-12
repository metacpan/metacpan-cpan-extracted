
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use Acme::Meta;
ok(1); # If we made it this far, we're ok.

$Acme::Meta::Meta::Pie = "good";
is ($Acme::Meta::Meta::Meta::Meta::Pie, "good");