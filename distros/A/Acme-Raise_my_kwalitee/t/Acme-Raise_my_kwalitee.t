# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-Raise_my_kwalitee.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Acme::Raise_my_kwalitee') };

#########################

# No tests - the module is meaningless anyway.
