use Test::More tests => 3;

use strict;
use warnings 'FATAL';

use DT;

my $time = 1518042015;
my $dt = DT->new($time);

my $unix_time = eval { $dt->unix_time };
is $@, '', "unix_time() no exception";
is $unix_time, $time, "unix_time() value";

my $want_str = '2018-02-07T22:20:15Z';
my $have_str = "$dt";

is $have_str, $want_str, "stringified value";

