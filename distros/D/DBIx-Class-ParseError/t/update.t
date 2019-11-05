use lib 't/lib';
use strict;
use warnings;
use Test::Roo;

with qw(Storage::SQLite Op::Update);

run_me('update');

done_testing;
