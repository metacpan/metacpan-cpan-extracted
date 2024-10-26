use Test2::V0 -target => 'DBIx::QuickORM::MetaTable';
use DBIx::QuickORM::Util qw/mod2file/;

ok(require(mod2file($CLASS)), "Load $CLASS");

done_testing;
