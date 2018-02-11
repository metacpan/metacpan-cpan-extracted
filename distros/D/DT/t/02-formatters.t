use Test::More tests => 2;

use strict;
use warnings 'FATAL';

use DT;

my $time = 1518042015;
my $dt = DT->new($time);

my $unix_time = eval { $dt->unix_time };
is $@, '', "unix_time() no exception";
is $unix_time, $time, "unix_time() value";
