# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::MySQL;
use DBIx::QuickORM::Dialect::SQLite;
use DBIx::QuickORM::Map;
use DBIx::QuickORM::Source::Query;
use DBIx::QuickORM::Source::Table;
use DBIx::QuickORM::SQLBuilder::SQLAbstract;
use DBIx::QuickORM::Value qw/raw inflated binary sql/;

my $D   = 'DBIx::QuickORM::Dialect::SQLite';
my $map = DBIx::QuickORM::Map->new(tables => {users => {fields => {id => {}, name => {}, 'we"ird' => {}}, pk => ['id']}});
my $t   = DBIx::QuickORM::Source::Table->new(table => 'users',                             db_map => $map);
my $q   = DBIx::QuickORM::Source::Query->new(sql   => 'SELECT id FROM users WHERE id > ?', binds  => [5]);
my $b   = DBIx::QuickORM::SQLBuilder::SQLAbstract->new;

ok($b->DOES('DBIx::QuickORM::Role::SQLBuilder'), "The builder composes the role");

subtest select => sub {
    is([$b->select($t, $D)], ['SELECT * FROM "users"', []], "Without fields every column is selected");
    is(
        [$b->select($t, $D, fields => ['id', 'we"ird'], where => {name => 'bob', id => {'>' => 3}}, order_by => [{-desc => 'name'}, 'id'])],
        ['SELECT "id", "we""ird" FROM "users" WHERE ( ( "id" > ? AND "name" = ? ) ) ORDER BY "name" DESC, "id"', [[id => 3], [name => 'bob']]],
        "Fields are quoted through the dialect; where and order use SQL::Abstract with column binds",
    );
    is([$b->select($t, $D, where => {name => undef})],              ['SELECT * FROM "users" WHERE ( "name" IS NULL )', []],              "undef is IS NULL");
    is([$b->select($t, $D, where => \['name = ?', [name => 'x']])], ['SELECT * FROM "users" WHERE ( name = ? )',       [[name => 'x']]], "Literal SQL binds are pairs");

    is([$b->select($t, $D, limit => 10)],              ['SELECT * FROM "users" LIMIT 10',                           []], "limit");
    is([$b->select($t, $D, limit => 10, offset => 5)], ['SELECT * FROM "users" LIMIT 10 OFFSET 5',                  []], "limit and offset");
    is([$b->select($t, $D, offset => 5)],              ['SELECT * FROM "users" LIMIT 9223372036854775807 OFFSET 5', []], "an offset alone gets the largest limit");

    like(dies { $b->select($t, $D, limit    => -1) },  qr/^'limit' must be a non-negative integer, got '-1'/,  "A negative limit croaks");
    like(dies { $b->select($t, $D, offset   => 'x') }, qr/^'offset' must be a non-negative integer, got 'x'/,  "and a non-number offset");
    like(dies { $b->select($t, $D, distinct => 1) },   qr/^Unknown request key\(s\) for select\(\): distinct/, "Unknown request keys croak");

    is([$b->select($q, $D)], ['SELECT id FROM users WHERE id > ?', [[undef, 5]]], "A query source with nothing added runs as written");
    is(
        [$b->select($q, $D, where => {id => 7}, limit => 1)],
        ['SELECT * FROM (SELECT id FROM users WHERE id > ?) qorm_query WHERE ( "id" = ? ) LIMIT 1', [[undef, 5], [id => 7]]],
        "and is a subquery when something is added, its binds first",
    );

    is([$b->select($t, 'DBIx::QuickORM::Dialect::MySQL', fields => ['id'], where => {name => 'x'})], ['SELECT `id` FROM `users` WHERE ( `name` = ? )', [[name => 'x']]], "Quoting follows the dialect");
};

subtest aggregate => sub {
    is(
        [$b->select($t, $D, fields => {n => sql('COUNT(*) + ?', 1), name => 'name'}, where => {id => {'>' => 1}}, group_by => ['name'], having => sql('COUNT(*) > ?', 2), order_by => {-desc => 'n'}, limit => 3)],
        ['SELECT COUNT(*) + ? AS "n", "name" AS "name" FROM "users" WHERE ( "id" > ? ) GROUP BY "name" HAVING ( COUNT(*) > ? ) ORDER BY "n" DESC LIMIT 3', [[undef, 1], [id => 1], [undef, 2]]],
        "Computed fields, then WHERE, GROUP BY, HAVING, ORDER BY, binds in that order",
    );
    my %agg = (fields => {n => sql('COUNT(*) + ?', 1), name => 'name'}, group_by => ['name'], having => {-or => [{n => {'>' => 2}}, {name => 'x'}]});
    is(
        [$b->select($t, $D, %agg)],
        ['SELECT COUNT(*) + ? AS "n", "name" AS "name" FROM "users" GROUP BY "name" HAVING ( ( (COUNT(*) + ?) > ? OR "name" = ? ) )', [[undef, 1], [undef, 1], [n => 2], [name => 'x']]],
        "having naming a computed column gets its SQL and binds where the dialect takes no alias there",
    );
    is(
        [$b->select($t, 'DBIx::QuickORM::Dialect::MySQL', %agg)],
        ['SELECT COUNT(*) + ? AS `n`, `name` AS `name` FROM `users` GROUP BY `name` HAVING ( ( `n` > ? OR `name` = ? ) )', [[undef, 1], [n => 2], [name => 'x']]],
        "and keeps the name where it does",
    );
    is(
        [$b->select($t, $D, fields => {flag => sql('COUNT(*) > 1 OR MAX(id) = 0')}, group_by => ['name'], having => {flag => 1})]->[0],
        'SELECT COUNT(*) > 1 OR MAX(id) = 0 AS "flag" FROM "users" GROUP BY "name" HAVING ( (COUNT(*) > 1 OR MAX(id) = 0) = ? )',
        "the column's SQL is parenthesized, so a low-precedence operator keeps its meaning",
    );
    is([$b->select($t, $D, fields => {k => 'u.name'}, group_by => ['u.name'], having => {'u.name' => 'x'})], ['SELECT "u"."name" AS "k" FROM "users" GROUP BY "u"."name" HAVING ( "u"."name" = ? )', [['u.name' => 'x']]], "Qualified names are quoted in parts");
    is([$b->select($t, $D, fields => ['users.name', 'id'])],                                                 ['SELECT "users"."name", "id" FROM "users"',                                            []],                  "in a plain field list too");
    is([$b->select($t, $D, fields => {top => ['MAX', 'u.we"ird']})],                                         ['SELECT MAX("u"."we""ird") AS "top" FROM "users"',                                     []],                  "[FUNC, field] renders FUNC(field) with the field quoted");
    is([$b->select($t, $D, fields => {n => ['COUNT', '*']})],                                                ['SELECT COUNT(*) AS "n" FROM "users"',                                                 []],                  "and FUNC(*) for the field '*', unquoted");
};

subtest where_builders => sub {
    my @chain = map { "DBIx::QuickORM::WhereBuilder::$_" } qw/RawSQL Simple SQLAbstract/;
    require "DBIx/QuickORM/WhereBuilder/$_.pm" for qw/RawSQL Simple/;

    is([$b->select($t, $D, where => 'id > 1', where_builders => \@chain)],                 ['SELECT * FROM "users" WHERE ( id > 1 )',                     []],                         "A string is raw SQL");
    is([$b->select($t, $D, where => {name => 'x'}, where_builders => \@chain)],            ['SELECT * FROM "users" WHERE ( "name" = ? )',                 [[name => 'x']]],            "A plain hash goes to Simple");
    is([$b->select($t, $D, where => {id => {'>' => 1}}, where_builders => \@chain)],       ['SELECT * FROM "users" WHERE ( "id" > ? )',                   [[id => 1]]],                "Anything else to SQLAbstract");
    is([$b->select($t, $D, where => {}, where_builders => \@chain)],                       ['SELECT * FROM "users"',                                      []],                         "An empty where is no WHERE");
    is([$b->count($t, $D, where => {name => 'x'}, where_builders => \@chain)],             ['SELECT COUNT(*) AS count FROM "users" WHERE ( "name" = ? )', [[name => 'x']]],            "count takes the chain");
    is([$b->delete($t, $D, where => 'id = 2', where_builders => \@chain)],                 ['DELETE FROM "users" WHERE ( id = 2 )',                       []],                         "delete too");
    is([$b->update($t, $D, {name => 'y'}, where => {id => 2}, where_builders => \@chain)], ['UPDATE "users" SET "name" = ? WHERE ( "id" = ? )',           [[name => 'y'], [id => 2]]], "and update");
    is(
        [$b->select($t, $D, fields => ['name'], where => 'id > 1', where_builders => [$chain[0]], group_by => ['name'], having => {name => 'x'})],
        ['SELECT "name" FROM "users" WHERE ( id > 1 ) GROUP BY "name" HAVING ( "name" = ? )', [[name => 'x']]],
        "having is not rendered through the chain, which here takes only raw SQL",
    );
    like(dies { $b->select($t, $D, where => 'id > 1', where_builders => [$chain[1]]) }, qr/^No where builder can build this where: id > 1/, "A where no builder takes croaks");
};

subtest count => sub {
    is([$b->count($t, $D)], ['SELECT COUNT(*) AS count FROM "users"', []], "count");
    is([$b->count($t, $D, where => {id => 1})], ['SELECT COUNT(*) AS count FROM "users" WHERE ( "id" = ? )', [[id => 1]]], "with a where");
    like(dies { $b->count($t, $D, limit => 1) }, qr/^Unknown request key\(s\) for count\(\): limit/, "count takes only a where");
};

subtest update => sub {
    is(
        [$b->update($t, $D, {name => 'x', id => 2}, where => {name => 'y'})],
        ['UPDATE "users" SET "id" = ?, "name" = ? WHERE ( "name" = ? )', [[id => 2], [name => 'x'], [name => 'y']]],
        "update sets each field, then the where",
    );
    is([$b->update($t, $D, {name => 'x'})], ['UPDATE "users" SET "name" = ?', [[name => 'x']]], "Without a where every row");
    like(dies { $b->update($t, $D, {}) }, qr/^update\(\) needs a hashref of at least one value/, "No values croaks");
};

subtest delete => sub {
    is([$b->delete($t, $D, where => {id => [1, 2]})], ['DELETE FROM "users" WHERE ( ( "id" = ? OR "id" = ? ) )', [[id => 1], [id => 2]]], "delete");
    is([$b->delete($t, $D)], ['DELETE FROM "users"', []], "Without a where every row");
};

subtest combine_where => sub {
    is($b->combine_where(op => 'and', left => {id => 1}, right => {name => 'x'}), {-and => [{id => 1}, {name => 'x'}]}, "and nests both sides under -and");
    is($b->combine_where(op => 'or',  left => {id => 1}, right => {name => 'x'}), {-or  => [{id => 1}, {name => 'x'}]}, "or under -or");
    is($b->combine_where(op => 'and', left => {},        right => {name => 'x'}), {name => 'x'},                        "An empty side drops out of and");
    is($b->combine_where(op => 'and', left => {id => 1}, right => []),            {id   => 1},                          "either side");
    is($b->combine_where(op => 'or', left => undef, right => {name => 'x'}), {}, "and makes or match every row");
    my $r = raw(1);
    is(
        [$b->select($t, $D, where => $b->combine_where(op => 'or', left => {id => $r}, right => {name => sql('= lower(?)', 'X')}))],
        ['SELECT * FROM "users" WHERE ( ( "id" = ? OR "name" = lower(?) ) )', [[id => exact_ref($r)], [undef, 'X']]],
        "Markers on either side still work",
    );
    is($b->combine_where(op => 'and', left => 'id > 1', right => {name => 'x'}), {-and => [\['( id > 1 )'], {name => 'x'}]}, "A plain-string side becomes literal SQL in parentheses");
    is($b->combine_where(op => 'or', left => {id => 1}, right => 'id > 1'), {-or => [{id => 1}, \['( id > 1 )']]}, "on either side");
    is(
        [$b->select($t, $D, where => $b->combine_where(op => 'or', left => 'id > 1', right => 'id < 0'))],
        ['SELECT * FROM "users" WHERE ( ( ( id > 1 ) OR ( id < 0 ) ) )', []],
        "and renders as raw SQL, even as both sides",
    );
    is(
        [$b->select($t, $D, where => $b->combine_where(op => 'and', left => 'id = 1 OR id = 2', right => {name => 'x'}))],
        ['SELECT * FROM "users" WHERE ( ( ( id = 1 OR id = 2 ) AND "name" = ? ) )', [[name => 'x']]],
        "The parentheses keep an OR in a raw side grouped",
    );
    is(
        [$b->select($t, $D, where => $b->combine_where(op => 'and', left => sql('id = ? OR id = ?', 1, 2), right => {name => 'x'}))],
        ['SELECT * FROM "users" WHERE ( ( ( id = ? OR id = ? ) AND "name" = ? ) )', [[undef, 1], [undef, 2], [name => 'x']]],
        "and in an sql marker side",
    );
    my $m = $b->combine_where(op => 'and', left => sql('id = ? OR id = ?', 1, 2), right => {name => 'x'})->{-and}->[0];
    is([$m->kind, $m->value, $m->binds], ['sql', '( id = ? OR id = ? )', [1, 2]], "An sql marker side becomes a new marker in parentheses, keeping its binds");
    is(
        $b->combine_where(op => 'or', left => \['id = ? OR id = ?', [id => 1], [id => 2]], right => {name => 'x'}),
        {-or => [\['( id = ? OR id = ? )', [id => 1], [id => 2]], {name => 'x'}]},
        "A \\[...] side is wrapped too, keeping its binds",
    );
    my $s_under = sql('= ?', 'x');
    my $h       = {name => $s_under, -and => [$s_under]};
    is($b->combine_where(op => 'and', left => $h, right => {id => 1}),     {-and => [exact_ref($h), {id => 1}]}, "A hash side is never recursed into, even with markers inside");
    is($b->combine_where(op => 'and', left => '', right => {name => 'x'}), {name => 'x'},                        "An empty string is an empty side");
    is($b->combine_where(op => 'or', left => {id => 1}, right => ''),      {},                                   "under or too");
    is([$b->select($t, $D, where => '')],                                  ['SELECT * FROM "users"', []],        "An empty-string where renders as none");
    like(dies { $b->combine_where(op => 'xor', left => {}, right => {}) }, qr/^combine_where\(\) takes op 'and' or 'or'/, "Any other op croaks");
    like(dies { $b->combine_where(op => 'and', bogus => 1) }, qr/^Unknown request key\(s\) for combine_where\(\): bogus/, "and so do unknown keys");
};

subtest markers => sub {
    my ($r, $i, $bin) = (raw('r'), inflated('i'), binary('b'));
    is(
        [$b->select($t, $D, where => {name => $r, id => {-in => [$i, 3]}, -or => [{id => $bin}, {name => {'!=' => $r}}]})],
        [
            'SELECT * FROM "users" WHERE ( ( ( "id" = ? OR "name" != ? ) AND "id" IN ( ?, ? ) AND "name" = ? ) )',
            [[id => exact_ref($bin)], [name => exact_ref($r)], [id => exact_ref($i)], [id => 3], [name => exact_ref($r)]],
        ],
        "raw, inflated, and binary markers become binds of the field they are under",
    );
    is(
        [$b->select($t, $D, where => {name => sql('= lower(?)', 'X'), id => {'>' => sql('? + 1', 2)}, -and => [sql('1 = ?', 1)]})],
        ['SELECT * FROM "users" WHERE ( ( 1 = ? AND "id" > ? + 1 AND "name" = lower(?) ) )', [[undef, 1], [undef, 2], [undef, 'X']]],
        "sql markers are literal SQL wherever they are: under a field it supplies its own operator",
    );
    is([$b->select($t, $D, where => {name => {'=' => sql('lower(?)', 'X')}})],    ['SELECT * FROM "users" WHERE ( "name" = lower(?) )',          [[undef, 'X']]],            "or follows one");
    is([$b->select($t, $D, where => {id => {-between => sql('? AND ?', 1, 3)}})], ['SELECT * FROM "users" WHERE ( ( "id" BETWEEN ? AND ? ) )',   [[undef, 1], [undef, 3]]],  "or an operator taking SQL as it is");
    is([$b->select($t, $D, where => [name => sql('= ?', 'a'), id => 1])],         ['SELECT * FROM "users" WHERE ( ( "name" = ? OR "id" = ? ) )', [[undef, 'a'], [id => 1]]], "in an array of pairs too");
    is(
        [$b->update($t, $D, {name => sql('upper(?)', 'x'), id => $bin}, where => {id => 1})],
        ['UPDATE "users" SET "id" = ?, "name" = upper(?) WHERE ( "id" = ? )', [[id => exact_ref($bin)], [undef, 'x'], [id => 1]]],
        "an sql marker as an update value is written into the SQL",
    );
};

subtest helpers => sub {
    ok($b->sqla($D)->isa('SQL::Abstract'), "sqla is an SQL::Abstract");
    ref_is($b->sqla($D), $b->sqla($D), "made once per quote character");
    ref_is_not($b->sqla($D), $b->sqla('DBIx::QuickORM::Dialect::MySQL'), "one per quote character");

    my ($r, $s) = (raw('r'), sql('= ?', 1));
    is($b->convert_where({a => $r, b => [$s], c => 1}), {a => {-value => exact_ref($r)}, b => [\['= ?', [undef, 1]]], c => 1}, "convert_where rewrites markers at any depth");
    is($b->convert_where([a => $s, $s]),                [a => \['= ?', [undef, 1]], \['= ?', [undef, 1]]],                     "convert_where does not look at position: every sql marker is left bare");

    is($b->convert_where({a => raw(undef), b => {'!=' => inflated(undef)}, c => binary(undef)}), {a => undef, b => {'!=' => undef}, c => undef}, "a marker holding undef becomes a plain undef");
};

done_testing;
