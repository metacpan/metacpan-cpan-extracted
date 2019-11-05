use lib 't/lib';
use strict;
use warnings;
use Test::Roo;

with qw(Storage::SQLite Op::Retrieve);

run_me('retrieve');

done_testing;
