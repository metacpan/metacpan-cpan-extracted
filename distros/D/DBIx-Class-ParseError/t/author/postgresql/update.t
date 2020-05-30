use lib 't/lib';
use Test::Roo;

with qw(Storage::PostgreSQL Op::Update);

run_me('update');

done_testing;
