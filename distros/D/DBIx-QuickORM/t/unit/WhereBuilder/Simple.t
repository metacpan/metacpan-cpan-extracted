# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::DuckDB;
use DBIx::QuickORM::Dialect::MariaDB;
use DBIx::QuickORM::Dialect::MySQL;
use DBIx::QuickORM::Dialect::PostgreSQL;
use DBIx::QuickORM::Dialect::SQLite;
use DBIx::QuickORM::Value qw/sql raw/;
use DBIx::QuickORM::WhereBuilder::Simple;
use DBIx::QuickORM::WhereBuilder::SQLAbstract;

my $B = 'DBIx::QuickORM::WhereBuilder::Simple';

subtest accepts => sub {
    ok($B->can_build_where({}), "An empty hash");
    ok($B->can_build_where({name         => 'bob', age => 3, gone => undef}), "Plain values and undef");
    ok($B->can_build_where({'users.name' => 'bob'}),                          "A qualified field");
    ok($B->can_build_where({n            => ''}),                             "An empty string value");

    my @declined = (
        [undef,       'undef'],
        ['id = 1',    'a string'],
        [[{id => 1}], 'an arrayref'],
        [{id      => [1, 2]},               'an arrayref value'],
        [{id      => {'>' => 1}},           'an operator hash'],
        [{id      => raw(1)},               'a value marker'],
        [{id      => sql('1')},             'an sql() marker'],
        [{id      => \'1'},                 'a scalar ref'],
        [{-and    => [{a => 1}, {b => 2}]}, 'nested -and'],
        [{-or     => [{a => 1}, {b => 2}]}, 'nested -or'],
        [{'a b'   => 1},                    'a key that is not a word'],
        [{'a.b.c' => 1},                    'a key with two dots'],
        [{'a"b'   => 1},                    'a key with a quote'],
        [{-bool   => 'flag'},               'an SQL::Abstract operator key'],
    );
    ok(!$B->can_build_where($_->[0]), "Declines $_->[1]") for @declined;
};

# Every shape Simple takes renders exactly as SQL::Abstract renders it, for every dialect's quoting.
subtest equivalent_to_sql_abstract => sub {
    my @keys   = ('id', 'name', 'users.email', 'x9');
    my @values = (1,    0, '', 'bob', '3.5', undef);
    my $SA     = 'DBIx::QuickORM::WhereBuilder::SQLAbstract';

    my @shapes = ({});
    for my $n (1 .. @keys) {
        for my $first (0 .. $#keys - $n + 1) {
            my @k = @keys[$first .. $first + $n - 1];
            for my $v (0 .. $#values) {
                push @shapes => {map { ($k[$_] => $values[($v + $_) % @values]) } 0 .. $#k};
            }
        }
    }

    for my $dialect (map { "DBIx::QuickORM::Dialect::$_" } qw/PostgreSQL MySQL MariaDB SQLite DuckDB/) {
        for my $where (@shapes) {
            my $shape = join ', ' => map { "$_ => " . ($where->{$_} // 'undef') } sort keys %$where;
            ok($B->can_build_where($where), "Simple takes {$shape}");
            is([$B->build_where($where, undef, $dialect)], [$SA->build_where($where, undef, $dialect)], "$dialect: {$shape} matches SQL::Abstract");
        }
    }
};

subtest build => sub {
    my $D = 'DBIx::QuickORM::Dialect::MySQL';
    is([$B->build_where({}, undef, $D)], ['', []], "No pairs, no condition");
    is([$B->build_where({b            => 2, a => undef}, undef, $D)], ['( ( `a` IS NULL AND `b` = ? ) )', [[b            => 2]]],   "Sorted, quoted, undef is IS NULL");
    is([$B->build_where({'users.name' => 'x'},           undef, $D)], ['( `users`.`name` = ? )',          [['users.name' => 'x']]], "A qualified name is quoted in parts");
};

done_testing;
