# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::SQLite;
use DBIx::QuickORM::Value qw/sql raw/;
use DBIx::QuickORM::WhereBuilder::RawSQL;

my $B = 'DBIx::QuickORM::WhereBuilder::RawSQL';
my $D = 'DBIx::QuickORM::Dialect::SQLite';

ok($B->can_build_where('id > 3'),         "A plain string is taken");
ok($B->can_build_where(''),               "even an empty one");
ok($B->can_build_where(sql('id > ?', 3)), "and an sql() marker");
ok(!$B->can_build_where($_),              "Declines " . (ref($_) || 'undef')) for undef, {id => 1}, [{id => 1}], \['id = ?', 1], raw(1);

is([$B->build_where('id > 3',         undef, $D)], ['( id > 3 )', []],           "A string is the SQL, in parentheses, with no binds");
is([$B->build_where(sql('id > ?', 3), undef, $D)], ['( id > ? )', [[undef, 3]]], "A marker brings its binds, which name no field");
is([$B->build_where('',               undef, $D)], ['',           []],           "An empty string is no condition");

done_testing;
