use lib 't/lib';
use strict;
use warnings;
use Test::Roo;

with qw(Storage::SQLite MissingTable);

run_me('missing table');

done_testing;
