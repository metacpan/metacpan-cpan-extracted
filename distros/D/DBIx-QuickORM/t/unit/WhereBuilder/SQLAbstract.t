# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::SQLite;
use DBIx::QuickORM::Value qw/sql raw/;
use DBIx::QuickORM::WhereBuilder::SQLAbstract;

my $B = 'DBIx::QuickORM::WhereBuilder::SQLAbstract';
my $D = 'DBIx::QuickORM::Dialect::SQLite';

ok($B->can_build_where($_), "Takes " . (ref($_) || 'a string')) for { id => 1 }
, [{id => 1}], 'id = 1', sql('1');

is([$B->build_where({id => {'>' => 3}, name => 'x'}, undef, $D)], ['( ( "id" > ? AND "name" = ? ) )', [[id => 3], [name => 'x']]], "SQL::Abstract's syntax, without the WHERE keyword");
is([$B->build_where({id => raw(5)}, undef, $D)],                  ['( "id" = ? )',                    [[id => raw(5)]]],           "A value marker is a bind of its field");
is([$B->build_where({id => sql('> ?', 2)}, undef, $D)],           ['( "id" > ? )',                    [[undef, 2]]],               "An sql() marker under a field is literal SQL");
is([$B->build_where({}, undef, $D)],                              ['',                                []],                         "An empty hash is no condition");

done_testing;
