# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 2 };

use Class::DBI::Sybase;
ok(1);

use Class::DBI::FreeTDS;
ok(1);
