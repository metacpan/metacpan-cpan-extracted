use lib 't/lib';
use strict;
use warnings;
use Test::Roo;

with qw(Storage::SQLite Op::Create);

run_me('create');

done_testing;
