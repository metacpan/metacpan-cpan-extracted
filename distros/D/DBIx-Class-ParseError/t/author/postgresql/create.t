use lib 't/lib';
use Test::Roo;

with qw(Storage::PostgreSQL Op::Create);

run_me('create');

done_testing;
