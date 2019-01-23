use strict;
use Test::More 0.98 tests => 8;

use lib './lib';

use_ok $_ for qw(Date::Cutoff::JP);
my $dco = new_ok('Date::Cutoff::JP');

is eval{ $dco->cutoff(-1) }, undef, "too small cutoff is denied";
is eval{ $dco->cutoff(32) }, undef, "too big cutoff is denied";

is eval{ $dco->payday(-1) }, undef, "too small payday is denied";
is eval{ $dco->payday(32) }, undef, "too big payday is denied";

is eval{ $dco->late(-1) }, undef, "too small lateness is denied";
is eval{ $dco->late(4) }, undef, "too big lateness is denied";


done_testing;

