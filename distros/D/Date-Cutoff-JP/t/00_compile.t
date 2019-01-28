use strict;
use Test::More 0.98 tests => 8;

use lib './lib';

use_ok $_ for qw(Date::Cutoff::JP);
my $dco = new_ok('Date::Cutoff::JP');

is eval{ $dco->cutoff(-1) }, undef, "Fail to assign too small cutoff";
is eval{ $dco->cutoff(32) }, undef, "Fail to assign too big cutoff";

is eval{ $dco->payday(-1) }, undef, "Fail to assign too small payday";
is eval{ $dco->payday(32) }, undef, "Fail to assign too big payday";

is eval{ $dco->late(-1) }, undef, "Fail to assign too small lateness";
is eval{ $dco->late(4) }, undef, "Fail to assign too big lateness";

done_testing;
